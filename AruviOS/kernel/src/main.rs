#![no_std]
#![no_main]

mod keyboard;
mod serial;
mod shell;
mod vga;

use core::panic::PanicInfo;

#[no_mangle]
pub extern "C" fn _start() -> ! {
    serial::init();
    vga::init();
    shell::banner();
    shell::repl();
}

#[panic_handler]
fn panic(info: &PanicInfo) -> ! {
    vga::clear_screen();
    vga::print_line("Kernel panic");

    let msg = info.message();
    vga::print_line("Reason:");
    vga::print_fmt(format_args!("{}", msg));

    loop {
        x86_64::instructions::hlt();
    }
}
