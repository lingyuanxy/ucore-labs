#!/usr/bin/env python3
"""Run reproducible WSL/Linux build and boot checks; no third-party packages."""
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
EVIDENCE = ROOT / "evidence"


def make(*args):
    return subprocess.check_output(["make", "--no-print-directory", *args],
                                   cwd=ROOT, text=True, stderr=subprocess.STDOUT)


def boot(mode, memory):
    qemu = make("print-qemu").strip()
    image = "bin/buddy/ucore.img" if mode == "buddy" else "bin/ucore.img"
    command = [qemu, "-machine", "virt", "-m", str(memory), "-nographic",
               "-bios", "default", "-device", f"loader,file={image},addr=0x80200000"]
    p = subprocess.Popen(command, cwd=ROOT, stdout=subprocess.PIPE,
                         stderr=subprocess.STDOUT, text=True)
    try:
        output, _ = p.communicate(timeout=3)
        raise RuntimeError(f"QEMU exited unexpectedly: {p.returncode}\n{output}")
    except subprocess.TimeoutExpired:
        p.terminate()
        output, _ = p.communicate(timeout=5)
    (EVIDENCE / f"boot-{mode}-{memory}M.txt").write_text(
        "$ " + " ".join(command) + "\n" + output, encoding="utf-8")
    assert "kernel panic" not in output.lower(), output
    assert "check_alloc_page() succeeded!" in output, output
    assert f"memory management: {'buddy' if mode == 'buddy' else 'best_fit'}_pmm_manager" in output
    expected_end = min(0x80000000 + memory * 1024 * 1024, 0x88000000)
    assert f"managed memory end: 0x{expected_end:016x}" in output, output
    if mode == "buddy":
        assert "[Buddy] alignment, rounding, splitting, exhaustion, non-buddy and coalescing: PASS" in output
    assert "[SLUB] size classes, alignment, payload, multi-slab, reuse, large objects and reclaim: PASS" in output
    print(f"PASS: {mode}, DTB RAM {memory} MiB, managed end {expected_end:#x}")


def main():
    EVIDENCE.mkdir(exist_ok=True)
    for mode in ("best_fit", "buddy"):
        build = make(f"PMM={mode}", "-j4")
        (EVIDENCE / f"build-{mode}.txt").write_text(build, encoding="utf-8")
        for memory in (64, 128, 256):
            boot(mode, memory)


if __name__ == "__main__":
    main()
