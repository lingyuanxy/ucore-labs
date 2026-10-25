set pagination off
set confirm off
set architecture riscv:rv64
file bin/kernel
set remotetimeout 10
target remote 127.0.0.1:40287
hbreak pmm_init
continue
set variable memory_base = 0x80000000
set variable memory_size = 0x300000
echo AUDIT INPUT: no-free-pages\n
print/x memory_base
print/x memory_size
hbreak __panic
hbreak buddy_check
continue
bt 5
frame 0
info args
echo EXPECTED PANIC OBSERVED\n
detach
quit
