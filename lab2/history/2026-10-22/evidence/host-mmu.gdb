set pagination off
set confirm off
set print pretty off
handle SIGPIPE nostop noprint pass
break get_physical_address if addr == 0x80200000 && env->satp == 0 && mmu_idx == 1
run
echo \n=== S-mode Bare instruction fetch ===\n
print/x addr
print/x env->satp
print mmu_idx
print access_type
bt 5
set $outpa = physical
finish
print/x *$outpa
disable breakpoints
break get_physical_address if addr == 0xffffffffc02000d6 && mmu_idx == 1
continue
echo \n=== S-mode Sv39 instruction fetch ===\n
print/x addr
print/x env->satp
print access_type
bt 6
set $outpa = physical
tbreak /home/lingyuan/.cache/ucore-qemu/qemu-4.1.1/target/riscv/cpu_helper.c:254
continue
echo \n=== Root PTE read: actual source-level stop ===\n
info locals
print/x base
print levels
print i
print ptshift
print/x idx
print/x pte_addr
print/x pte
next
next
next
echo \n=== Finish permission checks and translate ===\n
finish
print/x *$outpa
tbreak tlb_set_page
continue
echo \n=== TLB insertion ===\n
info args
bt 5
quit
