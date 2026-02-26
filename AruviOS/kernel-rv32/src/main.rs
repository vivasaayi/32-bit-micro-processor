//! AruviOS RV32 Kernel — Main Entry Point
//!
//! This is the Rust entry point for the AruviOS kernel running on RISC-V 32-bit.
//! The boot assembly (_entry in boot.S) sets up the stack, zeroes BSS, then
//! calls kmain().
//!
//! Platform support:
//!   - QEMU virt (default): NS16550A UART at 0x10000000
//!   - AruviX hardware:     Custom UART at 0xF0000000

#![no_std]
#![no_main]

mod shell;
mod uart;

use core::panic::PanicInfo;

// Include the boot assembly — this provides _entry, the true entry point
core::arch::global_asm!(include_str!("boot.S"));

// ─── Platform Constants ─────────────────────────────────────────────────────

/// QEMU virt machine: NS16550A UART at 0x10000000
#[cfg(feature = "qemu-virt")]
pub mod platform {
    pub const UART_BASE: usize = 0x1000_0000;
    pub const PLATFORM_NAME: &str = "QEMU virt (riscv32)";
}

/// AruviX custom processor: UART at 0xF0000000 (I/O space)
#[cfg(feature = "aruvix-hw")]
pub mod platform {
    pub const UART_BASE: usize = 0xF000_0000;
    pub const PLATFORM_NAME: &str = "AruviX RISC Processor";
}

// ─── Kernel Entry ───────────────────────────────────────────────────────────

/// Rust kernel entry point. Called by boot assembly after stack + BSS setup.
#[no_mangle]
pub extern "C" fn kmain() -> ! {
    // Initialize UART for serial output
    uart::init();

    // Print boot banner
    uart::puts("\n");
    uart::puts("========================================\n");
    uart::puts("  AruviX HobbyOS (RV32) \n");
    uart::puts("  Platform: ");
    uart::puts(platform::PLATFORM_NAME);
    uart::puts("\n");
    uart::puts("========================================\n");
    uart::puts("\n");

    // Show memory info
    uart::puts("[boot] Kernel running in M-mode\n");
    uart::puts("[boot] UART initialized at 0x");
    uart::put_hex(platform::UART_BASE as u32);
    uart::puts("\n");
    uart::puts("[boot] Stack set up, BSS zeroed\n");
    uart::puts("\n");

    // Start the interactive shell
    uart::puts("Type 'help' for available commands.\n\n");
    shell::repl();
}

// ─── Panic Handler ──────────────────────────────────────────────────────────

#[panic_handler]
fn panic(info: &PanicInfo) -> ! {
    uart::puts("\n!!! KERNEL PANIC !!!\n");

    if let Some(location) = info.location() {
        uart::puts("  at ");
        uart::puts(location.file());
        uart::puts(":");
        uart::put_dec(location.line());
        uart::puts("\n");
    }

    // Halt forever
    loop {
        // WFI — wait for interrupt (reduces power, acts as a hint to stop)
        unsafe { core::arch::asm!("wfi") };
    }
}
