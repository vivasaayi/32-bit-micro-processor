/*
 * AruviOS RV32 Linker Script
 *
 * Two platform targets:
 *   QEMU virt:  RAM at 0x80000000 (128MB)
 *   AruviX HW:  RAM at 0x00000000 (1MB), entry at 0x8000
 *
 * For now, targets QEMU virt. To switch to AruviX hardware,
 * change ORIGIN to 0x00008000 and LENGTH to 1M - 32K.
 */

OUTPUT_ARCH(riscv)
ENTRY(_entry)

MEMORY
{
    RAM (rwx) : ORIGIN = 0x80000000, LENGTH = 128M
}

SECTIONS
{
    /* Boot code must come first — _entry is the very first instruction */
    .text : {
        *(.text.entry)
        *(.text .text.*)
    } > RAM

    .rodata : ALIGN(4) {
        *(.rodata .rodata.*)
        *(.srodata .srodata.*)
    } > RAM

    .data : ALIGN(4) {
        *(.data .data.*)
        *(.sdata .sdata.*)
    } > RAM

    .bss : ALIGN(4) {
        _bss_start = .;
        *(.bss .bss.*)
        *(.sbss .sbss.*)
        _bss_end = .;
    } > RAM

    /* Kernel stack: 64KB, grows downward from _stack_top */
    . = ALIGN(16);
    _stack_bottom = .;
    . += 64K;
    _stack_top = .;

    /* Discard unwanted sections */
    /DISCARD/ : {
        *(.eh_frame)
        *(.comment)
        *(.note*)
    }
}
