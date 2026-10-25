set pagination off
set confirm off
set architecture riscv:rv64
file bin/kernel
set remotetimeout 10
target remote 127.0.0.1:12349
hbreak *0x80200000
continue
echo \n=== Physical kernel entry, paging disabled ===\n
info registers pc satp
x/8i $pc
hbreak *0xffffffffc02000d6
continue
echo \n=== Virtual C entry, paging enabled ===\n
info registers pc satp
x/8i $pc
p/x &boot_page_table_sv39
x/gx (char *)&boot_page_table_sv39+4088
stepi
stepi
info registers pc
detach
quit
