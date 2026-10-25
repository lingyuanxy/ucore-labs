#!/usr/bin/env python3
"""Inject parsed RAM inputs through GDB; never rewrite DTB or kernel sources."""
import hashlib
import json
import socket
import subprocess
from local_tools import CODE, EVIDENCE, configuration, make_arguments
from verify_partner import preservation


def main():
    preservation()
    config = configuration()
    subprocess.run(["make", *make_arguments(), "-j4"], cwd=CODE, check=True)
    cases = [
        ("zero-size", 0x80000000, 0, "invalid memory size"),
        ("base-above-kernel", 0x80300000, 0x1000000, "invalid memory base"),
        ("no-free-pages", 0x80000000, 0x300000, "no free memory available"),
        ("wrapped-end", 0x80000000, 0xffffffffffffffff, "invalid memory size"),
        ("unaligned-end", 0x80000000, 0x7ffffff, None),
        ("lower-base-clipping", 0x7ff00000, 0x8100000, None),
    ]
    results = []
    for name, base, size, panic in cases:
        with socket.socket() as probe:
            probe.bind(("127.0.0.1", 0))
            port = probe.getsockname()[1]
        qemu = subprocess.Popen([config["QEMU"], "-machine", "virt", "-m", "128",
            "-nographic", "-bios", "default", "-device",
            "loader,file=bin/ucore.img,addr=0x80200000", "-S", "-gdb", f"tcp:127.0.0.1:{port}"],
            cwd=CODE, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
        script = f"""set pagination off
set confirm off
set architecture riscv:rv64
file bin/kernel
set remotetimeout 10
target remote 127.0.0.1:{port}
hbreak pmm_init
continue
set variable memory_base = {base:#x}
set variable memory_size = {size:#x}
echo AUDIT INPUT: {name}\\n
print/x memory_base
print/x memory_size
hbreak __panic
hbreak buddy_check
continue
bt 5
"""
        if panic:
            script += "frame 0\ninfo args\necho EXPECTED PANIC OBSERVED\\n\n"
        else:
            expected_end = min(base + size, 0x88000000) & ~4095
            script += f"""if $pc != (unsigned long)&buddy_check
  echo UNEXPECTED STOP BEFORE CHECK\\n
  quit 1
end
print npage
print nbase
print/x pages
print kernel_state.nr_free
set $array_end = (unsigned long)pages + ((npage - nbase) * sizeof(struct Page) + 4095) / 4096 * 4096
set $free_start = ($array_end + 4095) / 4096 * 4096 - va_pa_offset
set $expect_count = ({expected_end:#x} - $free_start) / 4096
print/x $free_start
print $expect_count
if npage != {expected_end // 4096} || kernel_state.nr_free != $expect_count
  echo INVALID LAYOUT\\n
  quit 1
end
if (pages[0].flags & 1) == 0
  echo FIRST PAGE NOT RESERVED\\n
  quit 1
end
echo VALID LAYOUT OBSERVED\\n
"""
        script += "detach\nquit\n"
        script_path = EVIDENCE / f"page-init-{name}.gdb"
        script_path.write_text(script, encoding="utf-8")
        try:
            run = subprocess.run([config["GDB"], "-q", "-batch", "-nx", "-x", str(script_path)],
                                 cwd=CODE, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                                 text=True, timeout=20)
        finally:
            qemu.terminate()
            boot, _ = qemu.communicate(timeout=5)
        (EVIDENCE / f"page-init-{name}.txt").write_text(run.stdout + "\n=== QEMU ===\n" + boot,
                                                       encoding="utf-8")
        assert run.returncode == 0, run.stdout
        if panic:
            assert "__panic" in run.stdout and f'"{panic}"' in run.stdout, run.stdout
        else:
            assert "VALID LAYOUT OBSERVED" in run.stdout, run.stdout
        results.append({"case": name, "memory_base": hex(base), "memory_size": hex(size),
                        "expected": panic or "valid layout before allocator self-check", "passed": True})
        print(f"PASS page_init {name}: {panic or 'valid aligned layout'}", flush=True)
    (EVIDENCE / "page-init-summary.json").write_text(json.dumps({
        "method": "GDB changes cached parsed RAM values at pmm_init; DTB parser not fault-injected",
        "kernel_sha256": hashlib.sha256((CODE / "bin/kernel").read_bytes()).hexdigest(),
        "cases": results}, indent=2) + "\n", encoding="utf-8")
    preservation()


if __name__ == "__main__":
    main()
