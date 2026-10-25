#!/usr/bin/env python3
"""Run the untouched course checks with a debugger-selected Best Fit profile."""
import json
import os
import shutil
import signal
import subprocess
import tempfile
from pathlib import Path

from local_tools import ROOT, CODE, EVIDENCE, configuration
from verify_partner import preservation


def main():
    preservation()
    config = configuration()
    EVIDENCE.mkdir(parents=True, exist_ok=True)
    shim = ROOT / "support/grade_qemu.py"
    # NTFS workspaces may expose executable permissions through the mount;
    # chmod is still needed on ordinary Linux checkouts.
    shim.chmod(shim.stat().st_mode | 0o111)
    with tempfile.TemporaryDirectory(prefix="ucore-best-fit-") as scratch:
        work = Path(scratch) / "code"
        shutil.copytree(CODE, work, ignore=shutil.ignore_patterns("bin", "obj", ".qemu.out", ".gdb.in"))
        # Use the supplied injector exactly as the course grade target does.
        injected = subprocess.run(["python3", str(CODE / "tools/inject.py"), str(work)],
                                  capture_output=True, text=True, check=True)
        build_args = [f"{key}={value}" for key, value in config.items()]
        # This is an explicit debug build: at -O2, the diagnostic name argument
        # can be cached before the source-line stop, even though the pointer and
        # actual allocator have already been switched correctly.
        debug_flags = ("-mcmodel=medany -std=gnu99 -Wno-unused -Werror -fno-builtin "
                       "-Wall -O0 -nostdinc -fno-stack-protector -ffunction-sections "
                       "-fdata-sections -g -Ilibs/")
        build = subprocess.run(["make", *build_args, "CFLAGS=" + debug_flags, "-j4"], cwd=work,
                               capture_output=True, text=True, check=True)
        (EVIDENCE / "best-fit-grade-build.txt").write_text(
            "Debug profile CFLAGS=" + debug_flags + "\n" + injected.stdout + build.stdout + build.stderr)
        lines = (work / "kern/mm/pmm.c").read_text().splitlines()
        selection_line = next(i + 1 for i, line in enumerate(lines)
                              if 'cprintf("memory management:' in line)
        profile = {
            "qemu": config["QEMU"], "gdb": config["GDB"],
            "selection_line": selection_line,
            "gdb_script": str(EVIDENCE / "best-fit-selection.gdb"),
            "gdb_log": str(EVIDENCE / "best-fit-selection.txt"),
        }
        profile_file = Path(scratch) / "profile.json"
        profile_file.write_text(json.dumps(profile))
        env = os.environ.copy()
        env["LAB2_GRADE_PROFILE"] = str(profile_file)
        env["MAKEFLAGS"] = " ".join([*build_args, f"QEMU={shim}"])
        process = subprocess.Popen(["sh", "tools/grade.sh"], cwd=work, env=env,
                                   stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                                   text=True, start_new_session=True)
        try:
            output, _ = process.communicate(timeout=35)
        except subprocess.TimeoutExpired:
            os.killpg(process.pid, signal.SIGKILL)
            output, _ = process.communicate()
            raise RuntimeError("Best Fit course grading timed out: " + output)
        finally:
            try:
                os.killpg(process.pid, signal.SIGTERM)
            except ProcessLookupError:
                pass
        (EVIDENCE / "course-grade-best-fit.txt").write_text(output)
        serial = (work / ".qemu.out").read_text()
        (EVIDENCE / "best-fit-grade-boot.txt").write_text(serial)
        print(output, end="", flush=True)
        assert process.returncode == 0 and "Total Score: 20/20" in output, output
        assert "memory management: best_fit_pmm_manager" in serial, serial
        assert "check_alloc_page() succeeded!" in serial, serial
        assert "[Test 1] Page Init: PASS" in serial and "[Test 2] Best-Fit: PASS" in serial
        assert "slub_check: all tests passed; PMM pages restored" in serial, serial
        assert "=== Actual Best Fit init reached ===" in Path(profile["gdb_log"]).read_text()
    preservation()
    print("PASS: real Best Fit profile; default Buddy source and original test code unchanged", flush=True)


if __name__ == "__main__":
    main()
