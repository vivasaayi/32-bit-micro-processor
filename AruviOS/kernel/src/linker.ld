/* Linker script for AruviOS kernel
 * Links the kernel at physical/virtual address 0x100000 (1MB)
 * so the bootloader can load it with a simple identity map.
 */

ENTRY(_start)

SECTIONS {
    . = 0x100000;

    /* Text segment: _start must be at the very beginning */
    .text : {
        *(.text._start)
        *(.text*)
    }

    .rodata : ALIGN(0x1000) {
        *(.rodata*)
    }

    .data : ALIGN(0x1000) {
        *(.data*)
        *(.data.rel.ro*)
    }

    .bss : ALIGN(0x1000) {
        *(COMMON)
        *(.bss*)
    }

    /* Discard everything not needed for bare-metal execution */
    /DISCARD/ : {
        *(.eh_frame*)
        *(.debug*)
        *(.comment)
        *(.dynsym)
        *(.dynstr)
        *(.gnu.hash)
        *(.hash)
        *(.rela*)
        *(.relro_padding)
        *(.dynamic)
        *(.got*)
        *(.note*)
        *(.interp)
    }
}
