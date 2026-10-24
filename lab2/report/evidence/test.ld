OUTPUT_ARCH(riscv)
ENTRY(_start)
OFFSET = 0xFFFFFFFF40000000;
SECTIONS {
    . = 0x80000000;
    .boot : { *(.boot) }
    . = ALIGN(4096);
    .boot_data : { *(.boot_data) }
    . = 0xFFFFFFFFC0200000;
    .text : AT(ADDR(.text) - OFFSET) { *(.text .text.*) }
    .rodata : AT(ADDR(.rodata) - OFFSET) { *(.rodata .rodata.*) }
    .data : AT(ADDR(.data) - OFFSET) { *(.data .data.* .sdata .sdata.*) }
    .bss : AT(ADDR(.bss) - OFFSET) { *(.bss .bss.* .sbss .sbss.*) *(COMMON) }
}
