import hashlib
import json
import subprocess
from local_tools import CODE, EVIDENCE, configuration

config = configuration()
versions = {}
for key, executable in (("gcc", config["GCCPREFIX"] + "gcc"), ("guest_gdb", config["GDB"]),
                        ("qemu", config["QEMU"]), ("host_gdb", "gdb")):
    versions[key] = {"executable": executable, "version": subprocess.check_output(
        [executable, "--version"], text=True).splitlines()[0]}
artifacts = {name: hashlib.sha256((CODE / name).read_bytes()).hexdigest()
             for name in ("bin/kernel", "bin/ucore.img")}
(EVIDENCE / "local-environment.json").write_text(json.dumps(
    {"versions": versions, "artifacts_sha256": artifacts}, indent=2) + "\n", encoding="utf-8")
print("Recorded actual tool versions and current artifact hashes")
