use std::path::PathBuf;

use aruvi_emulator::Custom32Emulator;

fn parse_u32(s: &str) -> Result<u32, String> {
    let trimmed = s.trim();
    if let Some(rest) = trimmed.strip_prefix("0x") {
        u32::from_str_radix(rest, 16).map_err(|e| format!("invalid hex value '{s}': {e}"))
    } else {
        trimmed
            .parse::<u32>()
            .map_err(|e| format!("invalid value '{s}': {e}"))
    }
}

fn to_i32_bits(v: u32) -> i32 {
    i32::from_ne_bytes(v.to_ne_bytes())
}

fn main() {
    let args: Vec<String> = std::env::args().collect();
    if args.len() < 2 {
        eprintln!(
            "Usage: {} <assembly_file> [--trace] [--max-steps N] [--dump-addr ADDR]",
            args[0]
        );
        std::process::exit(1);
    }

    let assembly_file = PathBuf::from(&args[1]);
    let mut trace = false;
    let mut max_steps: usize = 1_000_000;
    let mut dump_addr: u32 = 0x2000;

    let mut i = 2;
    while i < args.len() {
        match args[i].as_str() {
            "--trace" => {
                trace = true;
                i += 1;
            }
            "--max-steps" => {
                if i + 1 >= args.len() {
                    eprintln!("--max-steps requires a value");
                    std::process::exit(2);
                }
                max_steps = args[i + 1].parse::<usize>().unwrap_or_else(|e| {
                    eprintln!("invalid --max-steps value: {e}");
                    std::process::exit(2);
                });
                i += 2;
            }
            "--dump-addr" => {
                if i + 1 >= args.len() {
                    eprintln!("--dump-addr requires a value");
                    std::process::exit(2);
                }
                dump_addr = parse_u32(&args[i + 1]).unwrap_or_else(|e| {
                    eprintln!("{e}");
                    std::process::exit(2);
                });
                i += 2;
            }
            other => {
                eprintln!("unknown option: {other}");
                std::process::exit(2);
            }
        }
    }

    let mut emu = Custom32Emulator::default();
    if let Err(e) = emu.load_assembly_file(&assembly_file) {
        eprintln!("load failed: {e}");
        std::process::exit(3);
    }
    if let Err(e) = emu.run(max_steps, trace) {
        eprintln!("run failed: {e}");
        std::process::exit(4);
    }

    match emu.read_word(dump_addr) {
        Ok(v) => {
            println!("{}", emu.summary());
            println!("mem[0x{dump_addr:08X}] = 0x{v:08X} ({})", to_i32_bits(v));
        }
        Err(e) => {
            eprintln!("dump failed: {e}");
            std::process::exit(5);
        }
    }
}
