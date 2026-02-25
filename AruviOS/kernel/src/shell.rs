use crate::{keyboard, serial, vga};

const MAX_INPUT: usize = 128;

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
];

pub fn banner() {
    vga::print_line("AruviX HobbyOS (Rust)");
    vga::print_line("Type 'help' for commands.\n");
}

pub fn repl() -> ! {
    let mut input = [0u8; MAX_INPUT];

    loop {
        vga::print("$ ");
        let len = read_line(&mut input);
        let line = core::str::from_utf8(&input[..len]).unwrap_or_default();
        handle_command(line);
    }
}

fn read_line(buf: &mut [u8; MAX_INPUT]) -> usize {
    let mut len = 0;

    loop {
        let Some(c) = serial::try_read_char().or_else(keyboard::try_read_char) else {
            x86_64::instructions::hlt();
            continue;
        };

        match c {
            '\n' => {
                vga::print("\n");
                return len;
            }
            '\u{8}' => {
                if len > 0 {
                    len -= 1;
                    vga::print("\u{8} \u{8}");
                }
            }
            ch => {
                if len < MAX_INPUT - 1 {
                    buf[len] = ch as u8;
                    len += 1;
                    let mut tmp = [0u8; 4];
                    let rendered = ch.encode_utf8(&mut tmp);
                    vga::print(rendered);
                }
            }
        }
    }
}

fn handle_command(line: &str) {
    let trimmed = line.trim();
    if trimmed.is_empty() {
        return;
    }

    let mut parts = trimmed.split_whitespace();
    let Some(cmd) = parts.next() else {
        return;
    };
    let args: heapless::Vec<&str, 16> = parts.collect();

    match cmd {
        "help" => {
            vga::print_line("Builtins: help, ls, run <utility>, clear");
            vga::print_line("Utilities:");
            for util in UTILITIES {
                vga::print("  - ");
                vga::print_line(util.help);
            }
        }
        "ls" => {
            for util in UTILITIES {
                vga::print_line(util.name);
            }
        }
        "run" => {
            if args.is_empty() {
                vga::print_line("usage: run <utility> [args]");
                return;
            }

            let target = args[0];
            let rest = &args[1..];
            if let Some(util) = UTILITIES.iter().find(|u| u.name == target) {
                (util.runner)(rest);
            } else {
                vga::print_line("utility not found");
            }
        }
        "clear" => vga::clear_screen(),
        _ => vga::print_line("unknown command"),
    }
}

fn util_echo(args: &[&str]) {
    if args.is_empty() {
        vga::print_line("");
        return;
    }

    for (i, arg) in args.iter().enumerate() {
        if i > 0 {
            vga::print(" ");
        }
        vga::print(arg);
    }
    vga::print("\n");
}

fn util_sum(args: &[&str]) {
    if args.len() != 2 {
        vga::print_line("usage: run sum <a> <b>");
        return;
    }

    let a = parse_i32(args[0]);
    let b = parse_i32(args[1]);

    match (a, b) {
        (Some(x), Some(y)) => {
            let result = x + y;
            vga::print_line("result:");
            print_i32(result);
            vga::print("\n");
        }
        _ => vga::print_line("sum expects integer inputs"),
    }
}

fn util_about(_: &[&str]) {
    vga::print_line("Simple command shell for a hobby OS.");
    vga::print_line("Use this as the base to load utilities compiled from C/Rust.");
}

fn parse_i32(text: &str) -> Option<i32> {
    let bytes = text.as_bytes();
    if bytes.is_empty() {
        return None;
    }

    let (start, sign) = if bytes[0] == b'-' { (1, -1i32) } else { (0, 1i32) };
    if start == bytes.len() {
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

fn print_i32(value: i32) {
    let mut buf = [0u8; 12];
    let mut idx = buf.len();
    let mut n = value;
    let negative = n < 0;

    if n == 0 {
        vga::print("0");
        return;
    }

    if negative {
        n = -n;
    }

    while n > 0 {
        idx -= 1;
        buf[idx] = b'0' + (n % 10) as u8;
        n /= 10;
    }

    if negative {
        idx -= 1;
        buf[idx] = b'-';
    }

    let s = core::str::from_utf8(&buf[idx..]).unwrap_or("?");
    vga::print(s);
}
