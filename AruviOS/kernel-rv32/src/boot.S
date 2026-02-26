# AruviOS RV32 Boot Assembly
#
# Entry point for the kernel. Runs in M-mode (Machine mode).
# Sets up the stack, zeroes BSS, then jumps to Rust kmain().
#
# This code runs on:
#   - QEMU virt machine (riscv32, -bios none)
#   - AruviX custom RISC processor (M-mode at reset)

.section .text.entry
.global _entry

_entry:
    # ── Disable all interrupts during early boot ──
    csrw    mie, zero
    csrw    mstatus, zero

    # ── Set up trap vector (early trap handler) ──
    la      t0, _trap_handler
    csrw    mtvec, t0

    # ── Set up stack pointer ──
    # Stack grows downward from _stack_top (defined in linker.ld)
    la      sp, _stack_top

    # ── Zero BSS section ──
    # Required for Rust: uninitialized statics must be zero
    la      t0, _bss_start
    la      t1, _bss_end
bss_loop:
    bge     t0, t1, bss_done
    sw      zero, 0(t0)
    addi    t0, t0, 4
    j       bss_loop
bss_done:

    # ── Jump to Rust kernel entry ──
    call    kmain

    # ── If kmain ever returns, halt the hart ──
halt_loop:
    wfi
    j       halt_loop

# ── Minimal trap handler ──
# For now, just loops forever on any trap.
# Will be expanded to handle interrupts and syscalls.
.align 4
_trap_handler:
    # Save minimal context
    csrr    t0, mcause
    csrr    t1, mepc

    # TODO: proper interrupt/exception dispatch
    # For now, infinite loop on any trap
    j       _trap_handler
