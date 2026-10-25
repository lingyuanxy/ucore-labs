"""Machine configuration belongs outside the frozen partner source tree."""
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CODE = ROOT / "code"
EVIDENCE = ROOT / "validation" / "2026-10-25"


def configuration():
    home = Path.home()
    prefix = home / "riscv-elf-toolchains/bin/riscv64-unknown-elf-"
    values = {
        "GCCPREFIX": str(prefix) if Path(str(prefix) + "gcc").is_file() else "riscv64-unknown-elf-",
        "QEMU": "/opt/qemu-4.1.1/bin/qemu-system-riscv64",
    }
    path = ROOT / "Makefile.local"
    if path.is_file():
        for line in path.read_text().splitlines():
            if ":=" in line and not line.lstrip().startswith("#"):
                key, value = line.split(":=", 1)
                if key.strip() in ("GCCPREFIX", "QEMU", "GDB"):
                    values[key.strip()] = value.strip()
    values.setdefault("GDB", values["GCCPREFIX"] + "gdb")
    for name in ("QEMU", "GDB"):
        if not Path(values[name]).is_file() and shutil.which(values[name]) is None:
            raise RuntimeError(f"Configure {name} in {ROOT / 'Makefile.local'}")
    return values


def make_arguments():
    return [f"{key}={value}" for key, value in configuration().items()]
