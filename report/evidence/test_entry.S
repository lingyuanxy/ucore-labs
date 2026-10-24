.section .boot,"ax"
.globl _start
_start:
    li t0, -1
    csrw pmpaddr0, t0
    li t0, 0xf
    csrw pmpcfg0, t0
    la t0, test_page_table
    srli t0, t0, 12
    li t1, 8
    slli t1, t1, 60
    or t0, t0, t1
    csrw satp, t0
    sfence.vma
    lui sp, %hi(test_stack_top)
    addi sp, sp, %lo(test_stack_top)
    lui t0, %hi(test_main)
    addi t0, t0, %lo(test_main)
    csrw mepc, t0
    li t0, 0x800
    csrw mstatus, t0
    mret
.section .boot_data,"aw"
.balign 4096
test_page_table:
    .quad 0xcf
    .quad 0
    .quad (0x80000 << 10) | 0xcf
    .zero 8 * 508
    .quad (0x80000 << 10) | 0xcf
.section .bss
.balign 16
test_stack:
    .space 8192
test_stack_top:
