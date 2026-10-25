set pagination off
set confirm off
handle SIGPIPE nostop noprint pass
break /home/lingyuan/.cache/ucore-qemu/qemu-4.1.1/accel/tcg/cputlb.c:1030 if addr == 0xffffffffc02000d6
run
echo \n=== TLB lookup before refill ===\n
print/x addr
print mmu_idx
print index
print/x entry->addr_code
print/x (addr & ~4095ULL)
bt 4
disable breakpoints
tbreak riscv_cpu_tlb_fill
continue
echo \n=== Lookup missed and reached riscv_cpu_tlb_fill ===\n
info args
finish
finish
next
next
echo \n=== Lookup entry after refill ===\n
print/x entry->addr_code
print/x (addr & ~4095ULL)
break /home/lingyuan/.cache/ucore-qemu/qemu-4.1.1/accel/tcg/cputlb.c:1030 if addr >= 0xffffffffc0200000 && addr < 0xffffffffc0201000
continue
echo \n=== Later CPU code lookup on the same virtual page ===\n
print/x addr
print/x entry->addr_code
print/x (addr & ~4095ULL)
next
echo \n=== Hit bypassed refill branch ===\n
frame
quit
