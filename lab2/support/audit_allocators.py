#!/usr/bin/env python3
"""Reproduce reference First-Fit defects without changing protected sources."""
import json
from local_tools import ROOT, CODE, EVIDENCE, configuration
from verify_partner import preservation, run_log


def main():
    preservation()
    config = configuration()
    out = ROOT / "build" / "allocator-audit"
    out.mkdir(parents=True, exist_ok=True)
    sources = [ROOT / "support/audit_allocator_edges.c", ROOT / "report/evidence/test_entry.S"]
    sources += [CODE / "kern/mm" / name for name in ("best_fit_pmm.c", "buddy_pmm.c", "slub.c")]
    sources += [CODE / "libs" / name for name in ("string.c", "printfmt.c")]
    command = [config["GCCPREFIX"] + "gcc", "-mcmodel=medany", "-std=gnu99", "-O2", "-g",
               "-fno-builtin", "-fno-stack-protector", "-ffunction-sections", "-fdata-sections",
               "-nostdinc", "-nostdlib", "-Wall", "-Wno-unused", "-Werror"]
    command += ["-I" + str(CODE / name) for name in ("libs", "kern/mm", "kern/debug", "kern/driver")]
    command += ["-Wl,--gc-sections", "-T", str(ROOT / "report/evidence/test.ld"),
                "-o", str(out / "edges.elf"), *map(str, sources)]
    code, output = run_log(command, "allocator-edge-build.txt")
    assert code == 0, output
    code, output = run_log([config["QEMU"], "-machine", "virt", "-m", "128", "-nographic",
                            "-bios", "none", "-kernel", str(out / "edges.elf")],
                           "allocator-edge-tests.txt", timeout=15)
    assert code == 0 and "AUDIT COMPLETE: 2 known failures" in output, output
    assert output.count("KNOWN_FAILURE") == 2 and output.count("PASS ") == 4, output
    result = {"all_allocator_edge_cases_passed": False,
              "audit_reproduction_completed": True,
              "known_failures": ["First-Fit init_memmap tail insertion",
                                 "First-Fit free_pages tail insertion"],
              "best_fit_edge_cases_passed": True, "buddy_edge_cases_passed": True,
              "protected_sources_changed": False,
              "process_exit_meaning": "zero confirms reproduction, not defect-free allocators"}
    (EVIDENCE / "allocator-edge-summary.json").write_text(
        json.dumps(result, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(output, end="")
    preservation()


if __name__ == "__main__":
    main()
