set pagination off
set confirm off
set architecture riscv:rv64
file /tmp/ucore-slub-c33jba6m/build/bin/kernel
target remote 127.0.0.1:44687
hbreak *0xffffffffc0205d1e
continue
printf "=== FIRST BSS STORE IN MEMSET ===\n"
printf "pc=%#lx a5=%#lx a1=%#lx satp=%#lx\n", $pc, $a5, $a1, $satp
x/i $pc
printf "effective_store_va=%#lx\n", $a5 - 1
si
printf "after_store_pc=%#lx\n", $pc
x/bx 0xffffffffc020c020
detach
quit
