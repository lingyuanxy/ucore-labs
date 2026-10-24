set pagination off
set confirm off
set print pretty off
handle SIGPIPE nostop noprint pass
break get_physical_address if env->satp == 0 && mmu_idx == 3
run
printf "\n=== BARE/M-MODE TRANSLATION ===\n"
printf "addr=%#lx access_type=%d mmu_idx=%d satp=%#lx\n", addr, access_type, mmu_idx, env->satp
set $bare_out = physical
bt 5
finish
printf "bare_result=%#lx\n", *$bare_out
disable 1
break get_physical_address if env->satp == 0x800000000008020b && access_type == 1 && (addr >> 12) == (0xffffffffc020c020 >> 12)
continue
printf "\n=== SV39 KERNEL STORE ===\n"
printf "addr=%#lx access_type=%d mmu_idx=%d satp=%#lx\n", addr, access_type, mmu_idx, env->satp
set $guest_addr = addr
set $walk_out = physical
set $walk_prot = prot
set $root_pa = (env->satp & 0xfffffffffff) << 12
bt 9
frame 3
printf "\n=== TLB LOOKUP FRAME ===\n"
info locals
frame 0
tbreak /home/viewfinder/qemu-4.1.1/target/riscv/cpu_helper.c:256
continue
printf "\n=== PAGE TABLE WALK LOCALS ===\n"
info locals
printf "root=%#lx vpn2=%lu expected_pte_addr=%#lx\n", $root_pa, ($guest_addr >> 30) & 511, $root_pa + (($guest_addr >> 30) & 511) * 8
finish
printf "translated_page=%#lx byte_pa=%#lx prot=%d\n", *$walk_out, *$walk_out | ($guest_addr & 4095), *$walk_prot
disable 2
tbreak tlb_set_page if vaddr == ($guest_addr & 0xfffffffffffff000)
continue
printf "\n=== SOFTWARE TLB REFILL ===\n"
info args
bt 5
tbreak /home/viewfinder/qemu-4.1.1/accel/tcg/cputlb.c:835
continue
printf "\n=== NEW SOFTWARE TLB ENTRY ===\n"
info locals
kill
quit
