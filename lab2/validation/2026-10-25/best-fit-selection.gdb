set pagination off
set confirm off
set remotetimeout 10
file bin/kernel
target remote 127.0.0.1:52247
hbreak kern/mm/pmm.c:40
continue
echo \n=== Before PMM init: original default ===\n
print pmm_manager->name
set variable pmm_manager = &best_fit_pmm_manager
echo \n=== Best Fit validation profile selected before init ===\n
print pmm_manager->name
delete breakpoints
hbreak best_fit_init
continue
echo \n=== Actual Best Fit init reached ===\n
bt 3
delete breakpoints
hbreak best_fit_check
continue
echo \n=== Actual Best Fit allocator check reached ===\n
print pmm_manager->name
bt 3
delete breakpoints
detach
quit
