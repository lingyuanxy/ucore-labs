#!/usr/bin/env python3
"""QEMU adapter for the separate Best Fit grading session, not normal boot."""
import json
import os
import socket
import subprocess
import sys
import time
from pathlib import Path


def main():
    config = json.loads(Path(os.environ["LAB2_GRADE_PROFILE"]).read_text())
    if "-help" in sys.argv[1:] or "--help" in sys.argv[1:]:
        return subprocess.call([config["qemu"], *sys.argv[1:]])
    with socket.socket() as endpoint:
        endpoint.bind(("127.0.0.1", 0))
        port = endpoint.getsockname()[1]
    script = f"""set pagination off
set confirm off
set remotetimeout 10
file bin/kernel
target remote 127.0.0.1:{port}
hbreak kern/mm/pmm.c:{config['selection_line']}
continue
echo \\n=== Before PMM init: original default ===\\n
print pmm_manager->name
set variable pmm_manager = &best_fit_pmm_manager
echo \\n=== Best Fit validation profile selected before init ===\\n
print pmm_manager->name
delete breakpoints
hbreak best_fit_init
continue
echo \\n=== Actual Best Fit init reached ===\\n
bt 3
delete breakpoints
hbreak best_fit_check
continue
echo \\n=== Actual Best Fit allocator check reached ===\\n
print pmm_manager->name
bt 3
delete breakpoints
detach
quit
"""
    Path(config["gdb_script"]).write_text(script)
    qemu = subprocess.Popen([config["qemu"], *sys.argv[1:], "-S",
                             "-gdb", f"tcp:127.0.0.1:{port}"])
    try:
        time.sleep(0.15)
        session = subprocess.run([config["gdb"], "-q", "-batch", "-nx", "-x",
                                  config["gdb_script"]], capture_output=True, text=True, timeout=20)
        Path(config["gdb_log"]).write_text(session.stdout + session.stderr)
        if session.returncode:
            return session.returncode
        return qemu.wait()
    finally:
        if qemu.poll() is None:
            qemu.terminate()
            qemu.wait(timeout=5)


if __name__ == "__main__":
    raise SystemExit(main())
