set pagination off
set confirm off
set architecture riscv:rv64
file bin/kernel
set remotetimeout 10
target remote 127.0.0.1:54651
hbreak pmm_init
continue
set variable memory_base = 0x80000000
set variable memory_size = 0x7ffffff
echo AUDIT INPUT: unaligned-end\n
print/x memory_base
print/x memory_size
hbreak __panic
hbreak buddy_check
continue
bt 5
if $pc != (unsigned long)&buddy_check
  echo UNEXPECTED STOP BEFORE CHECK\n
  quit 1
end
print npage
print nbase
print/x pages
print kernel_state.nr_free
set $array_end = (unsigned long)pages + ((npage - nbase) * sizeof(struct Page) + 4095) / 4096 * 4096
set $free_start = ($array_end + 4095) / 4096 * 4096 - va_pa_offset
set $expect_count = (0x87fff000 - $free_start) / 4096
print/x $free_start
print $expect_count
if npage != 557055 || kernel_state.nr_free != $expect_count
  echo INVALID LAYOUT\n
  quit 1
end
if (pages[0].flags & 1) == 0
  echo FIRST PAGE NOT RESERVED\n
  quit 1
end
echo VALID LAYOUT OBSERVED\n
detach
quit
