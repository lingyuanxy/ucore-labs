# Local integration entry. The partner's code/Makefile stays unchanged.
GCCPREFIX ?= riscv64-unknown-elf-
GDB ?= $(GCCPREFIX)gdb
QEMU ?= qemu-system-riscv64
-include Makefile.local

ifneq ($(strip $(PMM)),)
ifneq ($(PMM),buddy)
$(error The preserved source selects Buddy. PMM=$(PMM) is not supported by this entry)
endif
endif

.DEFAULT_GOAL := all
.PHONY: all qemu debug gdb grade grade-best-fit grade-original clean verify trace check-preservation
all qemu debug clean:
	$(MAKE) -C code GCCPREFIX="$(GCCPREFIX)" QEMU="$(QEMU)" GDB="$(GDB)" $(if $(filter all,$@),,$@)

# The regular kernel remains Buddy. Only this independent session selects Best Fit.
grade grade-best-fit:
	python3 support/grade_best_fit.py

grade-original:
	$(MAKE) -C code GCCPREFIX="$(GCCPREFIX)" QEMU="$(QEMU)" GDB="$(GDB)" grade

gdb:
	$(GDB) -ex 'file code/bin/kernel' -ex 'set arch riscv:rv64' -ex 'target remote 127.0.0.1:1234'

verify:
	python3 support/verify_partner.py

trace:
	python3 support/trace_mmu.py

check-preservation:
	python3 support/verify_partner.py --preservation-only
