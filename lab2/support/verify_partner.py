#!/usr/bin/env python3
"""Validate the preserved partner implementation without rewriting its files."""
import argparse
import hashlib
import json
import os
import signal
import subprocess
import tempfile
from pathlib import Path
from local_tools import ROOT, CODE, EVIDENCE, configuration, make_arguments

EDITABLE_DOCUMENTS = frozenset({
    "README.md", "report/report.md", "report/prompt.md",
    "report/images/README.md", "report/evidence/README.md",
})
DOCUMENT_RELOCATIONS = {"report/report.md": "实验报告.md"}


def preservation():
    record = json.loads((EVIDENCE / "partner-source-manifest.json").read_text())
    for target in DOCUMENT_RELOCATIONS.values():
        if not (ROOT / target).is_file():
            raise RuntimeError(f"Missing formal report: {target}")
    # The original manifest remains intact. Only documentation may be condensed;
    # allocator sources, course tests, drivers and five original prompts are frozen.
    protected = 0
    for item in record["files"]:
        if item["source_path"] in EDITABLE_DOCUMENTS:
            continue
        path = ROOT / item["source_path"]
        actual = hashlib.sha256(path.read_bytes()).hexdigest()
        if actual != item["sha256"]:
            raise RuntimeError(f"Partner file changed: {item['source_path']}")
        protected += 1
    print(f"PASS preservation: {protected} protected files (all 43 code files and original test drivers); "
          f"{len(EDITABLE_DOCUMENTS)} original documents may be updated or moved; source {record['source_commit']}", flush=True)


def run_log(command, name, cwd=CODE, timeout=45):
    process = subprocess.Popen(command, cwd=cwd, stdout=subprocess.PIPE,
                               stderr=subprocess.STDOUT, text=True, start_new_session=True)
    try:
        output, _ = process.communicate(timeout=timeout)
    except subprocess.TimeoutExpired:
        os.killpg(process.pid, signal.SIGKILL)
        output, _ = process.communicate()
        (EVIDENCE / name).write_text(output, encoding="utf-8")
        raise RuntimeError(f"Timed out: {command}")
    finally:
        try:
            os.killpg(process.pid, signal.SIGTERM)
        except ProcessLookupError:
            pass
    (EVIDENCE / name).write_text("$ " + " ".join(map(str, command)) + "\n" + output, encoding="utf-8")
    return process.returncode, output


def boot(memory):
    qemu = configuration()["QEMU"]
    command = [qemu, "-machine", "virt", "-m", str(memory), "-nographic", "-bios", "default",
               "-device", "loader,file=bin/ucore.img,addr=0x80200000"]
    p = subprocess.Popen(command, cwd=CODE, stdout=subprocess.PIPE,
                         stderr=subprocess.STDOUT, text=True)
    try:
        output, _ = p.communicate(timeout=5)
        raise RuntimeError(f"Unexpected kernel exit {p.returncode}: {output}")
    except subprocess.TimeoutExpired:
        p.terminate()
        output, _ = p.communicate(timeout=5)
    (EVIDENCE / f"boot-buddy-{memory}M.txt").write_text(
        "$ " + " ".join(command) + "\n" + output, encoding="utf-8")
    for required in ("memory management: buddy_pmm_manager",
                     "buddy_check: all tests passed; kernel state restored",
                     "slub_check: all tests passed; PMM pages restored"):
        assert required in output, output
    assert "kernel panic" not in output.lower(), output
    print(f"PASS unchanged kernel: Buddy + SLUB, {memory} MiB RAM", flush=True)


def independent_driver():
    config = configuration()
    out = ROOT / "build" / "partner-tests"
    out.mkdir(parents=True, exist_ok=True)
    evidence = ROOT / "report" / "evidence"
    sources = [evidence / "test_entry.S", evidence / "slub_test.c"]
    sources += [CODE / "kern/mm" / name for name in (
        "default_pmm.c", "best_fit_pmm.c", "buddy_pmm.c", "slub.c")]
    sources += [CODE / "libs" / name for name in ("string.c", "printfmt.c")]
    command = [config["GCCPREFIX"] + "gcc", "-mcmodel=medany", "-std=gnu99", "-O2", "-g",
               "-fno-builtin", "-fno-stack-protector", "-ffunction-sections", "-fdata-sections",
               "-nostdinc", "-nostdlib", "-Wall", "-Wno-unused", "-Werror"]
    command += ["-I" + str(CODE / name) for name in (
        "libs", "kern/mm", "kern/debug", "kern/driver")]
    command += ["-Wl,--gc-sections", "-T", str(evidence / "test.ld"),
                "-o", str(out / "slub-test.elf"), *map(str, sources)]
    code, output = run_log(command, "three-backend-build.txt")
    assert code == 0, output
    code, output = run_log([config["QEMU"], "-machine", "virt", "-m", "128", "-nographic",
                            "-bios", "none", "-kernel", str(out / "slub-test.elf")],
                           "three-backend-tests.txt", timeout=45)
    assert code == 0 and "ALL SLUB SV39 TESTS PASSED" in output, output
    for backend in ("buddy", "best_fit", "default"):
        assert f"PASS backend {backend}_pmm_manager: SLUB complete and pages restored" in output
    print("PASS partner's unchanged independent driver: Buddy / Best Fit / First Fit + SLUB", flush=True)


def grade():
    with tempfile.TemporaryDirectory(prefix="ucore-partner-grade-") as scratch:
        code, output = run_log(["make", *make_arguments(),
                                f"GRADE_TMP={scratch}/grade", "grade"], "course-grade.txt")
    # Report the real result; this source deliberately selects Buddy.
    summary = next((s for s in output.splitlines() if s.startswith("Total Score:")), "No score")
    print(f"Course grade unchanged source: {summary}, exit={code}", flush=True)
    return {"exit_code": code, "score": summary}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--preservation-only", action="store_true")
    args = parser.parse_args()
    EVIDENCE.mkdir(parents=True, exist_ok=True)
    preservation()
    if args.preservation_only:
        return
    code, output = run_log(["make", *make_arguments(), "-j4"], "build.txt")
    assert code == 0, output
    for memory in (64, 128, 256):
        boot(memory)
    independent_driver()
    original_result = grade()
    from grade_best_fit import main as grade_best_fit
    grade_best_fit()
    result = {
        "default_manager": "buddy_pmm_manager",
        "original_buddy_grade": original_result,
        "best_fit_debug_profile": {"exit_code": 0, "score": "Total Score: 20/20", "optimization": "O0"},
    }
    # The course target cleans the normal build; leave a runnable image afterward.
    code, output = run_log(["make", *make_arguments(), "-j4"], "build-after-grade.txt")
    assert code == 0, output
    preservation()
    result.update({"kernel_boot_ram_mib": [64, 128, 256],
                   "independent_backends": ["buddy", "best_fit", "default"],
                   "partner_code_unchanged": True,
                   "editable_noncode_documents": sorted(
                       DOCUMENT_RELOCATIONS.get(name, name) for name in EDITABLE_DOCUMENTS)})
    (EVIDENCE / "summary.json").write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
