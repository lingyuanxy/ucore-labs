#!/usr/bin/env python3
"""Capture real host-QEMU and guest-kernel GDB sessions on WSL/Linux."""
import argparse
import os
import signal
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
EVIDENCE = ROOT / "evidence"


def make_value(name):
    return subprocess.check_output(["make", "-s", f"print-{name}"], cwd=ROOT, text=True).strip()


def run_logged(command, target, timeout=40):
    p = subprocess.Popen(command, cwd=ROOT, stdout=subprocess.PIPE,
                         stderr=subprocess.STDOUT, text=True, start_new_session=True)
    try:
        output, _ = p.communicate(timeout=timeout)
    except subprocess.TimeoutExpired:
        os.killpg(p.pid, signal.SIGKILL)
        output, _ = p.communicate()
        target.write_text(output, encoding="utf-8")
        raise RuntimeError(f"GDB timed out; see {target}")
    target.write_text(output, encoding="utf-8")
    if p.returncode:
        raise RuntimeError(f"GDB failed ({p.returncode}); see {target}")
    return output


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--qemu-debug", default=str(Path.home() /
        ".cache/ucore-qemu/qemu-4.1.1/riscv64-softmmu/qemu-system-riscv64"))
    parser.add_argument("--source", default=str(Path.home() / ".cache/ucore-qemu/qemu-4.1.1"))
    args = parser.parse_args()
    subprocess.run(["make", "-j4"], cwd=ROOT, check=True)
    prefix = make_value("gccprefix")
    symbols = subprocess.check_output([prefix + "nm", "bin/kernel"], cwd=ROOT, text=True)
    addresses = {row.split()[2]: int(row.split()[0], 16)
                 for row in symbols.splitlines() if len(row.split()) == 3}
    entry = addresses["kern_init"]
    EVIDENCE.mkdir(exist_ok=True)
    source = Path(args.source) / "target/riscv/cpu_helper.c"
    lines = source.read_text().splitlines()
    pte_line = next(i + 1 for i, s in enumerate(lines) if "target_ulong ppn = pte >>" in s)

    host_script = f"""set pagination off
set confirm off
set print pretty off
handle SIGPIPE nostop noprint pass
break get_physical_address if addr == 0x80200000 && env->satp == 0 && mmu_idx == 1
run
echo \\n=== S-mode Bare instruction fetch ===\\n
print/x addr
print/x env->satp
print mmu_idx
print access_type
bt 5
set $outpa = physical
finish
print/x *$outpa
disable breakpoints
break get_physical_address if addr == {entry:#x} && mmu_idx == 1
continue
echo \\n=== S-mode Sv39 instruction fetch ===\\n
print/x addr
print/x env->satp
print access_type
bt 6
set $outpa = physical
tbreak {source}:{pte_line}
continue
echo \\n=== Root PTE read: actual source-level stop ===\\n
info locals
print/x base
print levels
print i
print ptshift
print/x idx
print/x pte_addr
print/x pte
next
next
next
echo \\n=== Finish permission checks and translate ===\\n
finish
print/x *$outpa
tbreak tlb_set_page
continue
echo \\n=== TLB insertion ===\\n
info args
bt 5
quit
"""
    script_path = EVIDENCE / "host-mmu.gdb"
    script_path.write_text(host_script, encoding="utf-8")
    host_output = run_logged(["gdb", "-q", "-batch", "-nx", "-x", str(script_path),
                "--args", args.qemu_debug, "-machine", "virt", "-nographic", "-bios", "default",
                "-device", "loader,file=bin/ucore.img,addr=0x80200000"], EVIDENCE / "host-mmu.txt")
    assert "=== TLB insertion ===" in host_output
    print("PASS: host GDB Bare/Sv39 page walk and TLB insertion captured")

    # Observe the lookup itself before and after a real miss/refill.
    cputlb = Path(args.source) / "accel/tcg/cputlb.c"
    lookup_line = next(i + 1 for i, s in enumerate(cputlb.read_text().splitlines())
                       if "if (unlikely(!tlb_hit(entry->addr_code, addr)))" in s)
    tlb_script = f"""set pagination off
set confirm off
handle SIGPIPE nostop noprint pass
break {cputlb}:{lookup_line} if addr == {entry:#x}
run
echo \\n=== TLB lookup before refill ===\\n
print/x addr
print mmu_idx
print index
print/x entry->addr_code
print/x (addr & ~4095ULL)
bt 4
disable breakpoints
tbreak riscv_cpu_tlb_fill
continue
echo \\n=== Lookup missed and reached riscv_cpu_tlb_fill ===\\n
info args
finish
finish
next
next
echo \\n=== Lookup entry after refill ===\\n
print/x entry->addr_code
print/x (addr & ~4095ULL)
break {cputlb}:{lookup_line} if addr >= {entry & ~4095:#x} && addr < {(entry & ~4095) + 4096:#x}
continue
echo \\n=== Later CPU code lookup on the same virtual page ===\\n
print/x addr
print/x entry->addr_code
print/x (addr & ~4095ULL)
next
echo \\n=== Hit bypassed refill branch ===\\n
frame
quit
"""
    tlb_path = EVIDENCE / "host-tlb.gdb"
    tlb_path.write_text(tlb_script, encoding="utf-8")
    tlb_output = run_logged(["gdb", "-q", "-batch", "-nx", "-x", str(tlb_path),
                "--args", args.qemu_debug, "-machine", "virt", "-nographic", "-bios", "default",
                "-device", "loader,file=bin/ucore.img,addr=0x80200000"], EVIDENCE / "host-tlb.txt")
    assert "=== Hit bypassed refill branch ===" in tlb_output
    print("PASS: real TLB miss/refill and subsequent same-page hit captured")

    # A separate guest run avoids debugger memory reads influencing the host trace.
    qemu = subprocess.Popen([make_value("qemu"), "-machine", "virt", "-nographic",
        "-bios", "default", "-device", "loader,file=bin/ucore.img,addr=0x80200000",
        "-S", "-gdb", "tcp:127.0.0.1:12349"], cwd=ROOT,
        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    guest_script = f"""set pagination off
set confirm off
set architecture riscv:rv64
file bin/kernel
set remotetimeout 10
target remote 127.0.0.1:12349
hbreak *0x80200000
continue
echo \\n=== Physical kernel entry, paging disabled ===\\n
info registers pc satp
x/8i $pc
hbreak *{entry:#x}
continue
echo \\n=== Virtual C entry, paging enabled ===\\n
info registers pc satp
x/8i $pc
p/x &boot_page_table_sv39
x/gx &boot_page_table_sv39+4088
stepi
stepi
info registers pc
detach
quit
"""
    # Cast to byte address: GDB's assembly symbol has no C pointer element size.
    guest_script = guest_script.replace("&boot_page_table_sv39+4088", "(char *)&boot_page_table_sv39+4088")
    guest_path = EVIDENCE / "guest-kernel.gdb"
    guest_path.write_text(guest_script, encoding="utf-8")
    try:
        guest_output = run_logged([make_value("gdb"), "-q", "-batch", "-nx", "-x", str(guest_path)],
                                  EVIDENCE / "guest-kernel.txt")
        assert "=== Virtual C entry" in guest_output
        print("PASS: guest GDB physical/virtual entries, satp, root PTE and instruction steps captured")
    finally:
        qemu.terminate()
        qemu.wait(timeout=5)


if __name__ == "__main__":
    main()
