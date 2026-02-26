//! AruviOS Shell for RV32
//!
//! Interactive command shell over UART serial.
//! Mirrors the x86_64 kernel shell but uses UART instead of VGA.

use crate::uart;

const MAX_INPUT: usize = 128;

// ─── Built-in Utilities ─────────────────────────────────────────────────────

type UtilityFn = fn(&[&str]);

struct Utility {
    name: &'static str,
    help: &'static str,
    runner: UtilityFn,
}

static UTILITIES: &[Utility] = &[
    Utility {
        name: "echo",
        help: "echo [text] - prints text",
        runner: util_echo,
    },
    Utility {
        name: "sum",
        help: "sum a b - adds two integers",
        runner: util_sum,
    },
    Utility {
        name: "about",
        help: "about - project info",
        runner: util_about,
    },
    Utility {
        name: "mem",
        help: "mem <addr> - read 32-bit word at hex address",
        runner: util_mem,
    },
    Utility {
        name: "memw",
        help: "memw <addr> <val> - write 32-bit word to hex address",
        runner: util_memw,
    },
];

// ─── REPL ───────────────────────────────────────────────────────────────────

/// Run the Read-Eval-Print Loop. Never returns.
pub fn repl() -> ! {
    let mut input = [0u8; MAX_INPUT];

    loop {
        uart::puts("$ ");
        let len = read_line(&mut input);
        let line = core::str::from_utf8(&input[..len]).unwrap_or_default();
        handle_command(line);
    }
}

/// Read a line from UART, echoing characters back.
fn read_line(buf: &mut [u8; MAX_INPUT]) -> usize {
    let mut len = 0;

    loop {
        // Poll UART for input
        let Some(c) = uart::getc() else {
            // No data — yield the hart briefly
            unsafe { core::arch::asm!("wfi") };
            continue;
        };

        match c {
            b'\r' | b'\n' => {
                uart::puts("\n");
                return len;
            }
            // Backspace (0x08) or DEL (0x7F)
            0x08 | 0x7F => {
                if len > 0 {
                    len -= 1;
                    // Erase character on terminal: backspace, space, backspace
                    uart::putc(0x08);
                    uart::putc(b' ');
                    uart::putc(0x08);
                }
            }
            // Printable ASCII
            0x20..=0x7E => {
                if len < MAX_INPUT - 1 {
                    buf[len] = c;
                    len += 1;
                    uart::putc(c); // Echo
                }
            }
            _ => {} // Ignore control characters
        }
    }
}

// ─── Command Dispatch ───────────────────────────────────────────────────────

fn handle_command(line: &str) {
    let trimmed = line.trim();
    if trimmed.is_empty() {
        return;
    }

    // Split into command + args (max 16 args)
    let mut parts = trimmed.split_whitespace();
    let Some(cmd) = parts.next() else {
        return;
    };

    // Collect args into a fixed-size array (no heap allocation)
    let mut args_buf: [&str; 16] = [""; 16];
    let mut argc = 0;
    for arg in parts {
        if argc < 16 {
            args_buf[argc] = arg;
            argc += 1;
        }
    }
    let args = &args_buf[..argc];

    match cmd {
        "help" => {
            uart::puts("Built-in commands:\n");
            uart::puts("  help         - show this help\n");
            uart::puts("  ls           - list utilities\n");
            uart::puts("  run <name>   - run a utility\n");
            uart::puts("  clear        - clear screen\n");
            uart::puts("\nUtilities:\n");
            for util in UTILITIES {
                uart::puts("  ");
                uart::puts(util.help);
                uart::puts("\n");
            }
        }
        "ls" => {
            for util in UTILITIES {
                uart::puts(util.name);
                uart::puts("\n");
            }
        }
        "run" => {
            if args.is_empty() {
                uart::puts("usage: run <utility> [args]\n");
                return;
            }
            let target = args[0];
            let rest = &args[1..];
            if let Some(util) = UTILITIES.iter().find(|u| u.name == target) {
                (util.runner)(rest);
            } else {
                uart::puts("utility not found: ");
                uart::puts(target);
                uart::puts("\n");
            }
        }
        "clear" => {
            // ANSI escape: clear screen + move cursor home
            uart::puts("\x1b[2J\x1b[H");
        }
        _ => {
            // Try direct utility name (convenience — no need for "run" prefix)
            if let Some(util) = UTILITIES.iter().find(|u| u.name == cmd) {
                (util.runner)(args);
            } else {
                uart::puts("unknown command: ");
                uart::puts(cmd);
                uart::puts("\n");
            }
        }
    }
}

// ─── Utility Implementations ────────────────────────────────────────────────

fn util_echo(args: &[&str]) {
    for (i, arg) in args.iter().enumerate() {
        if i > 0 {
            uart::putc(b' ');
        }
        uart::puts(arg);
    }
    uart::puts("\n");
}

fn util_sum(args: &[&str]) {
    if args.len() != 2 {
        uart::puts("usage: sum <a> <b>\n");
        return;
    }

    match (parse_i32(args[0]), parse_i32(args[1])) {
        (Some(a), Some(b)) => {
            uart::puts("= ");
            uart::put_i32(a.wrapping_add(b));
            uart::puts("\n");
        }
        _ => uart::puts("error: expected integer arguments\n"),
    }
}

fn util_about(_: &[&str]) {
    uart::puts("AruviX HobbyOS — RV32IM Bare Metal Kernel\n");
    uart::puts("Part of the AruviX full-vertical computing stack:\n");
    uart::puts("  Processor (Verilog) → OS → C Compiler → Assembler → JVM\n");
    uart::puts("  All targeting FPGA deployment on PYNQ-Z2\n");
}

/// Read a 32-bit word from a memory address (hex).
fn util_mem(args: &[&str]) {
    if args.is_empty() {
        uart::puts("usage: mem <hex_addr>\n");
        return;
    }
    match parse_hex(args[0]) {
        Some(addr) => {
            let val = unsafe { core::ptr::read_volatile(addr as *const u32) };
            uart::puts("0x");
            uart::put_hex(addr);
            uart::puts(" = 0x");
            uart::put_hex(val);
            uart::puts("\n");
        }
        None => uart::puts("error: invalid hex address\n"),
    }
}

/// Write a 32-bit word to a memory address (hex).
fn util_memw(args: &[&str]) {
    if args.len() != 2 {
        uart::puts("usage: memw <hex_addr> <hex_val>\n");
        return;
    }
    match (parse_hex(args[0]), parse_hex(args[1])) {
        (Some(addr), Some(val)) => {
            unsafe { core::ptr::write_volatile(addr as *mut u32, val) };
            uart::puts("wrote 0x");
            uart::put_hex(val);
            uart::puts(" to 0x");
            uart::put_hex(addr);
            uart::puts("\n");
        }
        _ => uart::puts("error: invalid hex value\n"),
    }
}

// ─── Parsing Helpers ────────────────────────────────────────────────────────

fn parse_i32(text: &str) -> Option<i32> {
    let bytes = text.as_bytes();
    if bytes.is_empty() {
        return None;
    }

    let (start, sign) = if bytes[0] == b'-' {
        (1, -1i32)
    } else {
        (0, 1i32)
    };

    if start >= bytes.len() {
        return None;
    }

    let mut acc: i32 = 0;
    for &b in &bytes[start..] {
        if !b.is_ascii_digit() {
            return None;
        }
        acc = acc.checked_mul(10)?;
        acc = acc.checked_add((b - b'0') as i32)?;
    }

    acc.checked_mul(sign)
}

fn parse_hex(text: &str) -> Option<u32> {
    // Strip optional "0x" prefix
    let s = if text.starts_with("0x") || text.starts_with("0X") {
        &text[2..]
    } else {
        text
    };

    if s.is_empty() || s.len() > 8 {
        return None;
    }

    let mut val: u32 = 0;
    for &b in s.as_bytes() {
        let digit = match b {
            b'0'..=b'9' => b - b'0',
            b'a'..=b'f' => b - b'a' + 10,
            b'A'..=b'F' => b - b'A' + 10,
            _ => return None,
        };
        val = val.checked_shl(4)?;
        val |= digit as u32;
    }

    Some(val)
}
