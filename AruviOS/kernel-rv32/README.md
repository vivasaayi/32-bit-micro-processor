# AruviOS RV32 Kernel

Minimal bare-metal kernel for RISC-V 32-bit, part of the AruviX full vertical computing stack.

## What This Is

This is the **RV32 port** of AruviOS. While the original `kernel/` targets x86_64, this kernel targets the **AruviX custom RISC processor** (RV32IM ISA) and uses QEMU's `virt` machine as a development/testing platform.

## Architecture

```
boot.S (assembly)          → Set up stack, zero BSS, jump to Rust
  ↓
kmain() (main.rs)          → Initialize UART, print banner
  ↓
shell::repl() (shell.rs)   → Interactive command shell over serial UART
  ↓
uart.rs                    → Platform-abstracted UART driver
                              - QEMU virt: NS16550A at 0x10000000
                              - AruviX HW: Custom UART at 0xF0000000
```

## Platform Support

| Platform | UART | RAM Base | Entry | Feature Flag |
|---|---|---|---|---|
| **QEMU virt** (default) | NS16550A @ 0x10000000 | 0x80000000 | ELF entry | `qemu-virt` |
| **AruviX Hardware** | Custom @ 0xF0000000 | 0x00000000 | 0x8000 | `aruvix-hw` |

## Quick Start

```bash
# Build the kernel
./build_rv32.sh build

# Launch interactive session
./start.sh
```

### Manual Build & Run

```bash
cargo +nightly build --release \
    --features qemu-virt \
    -Z build-std=core \
    -Z build-std-features=compiler-builtins-mem \
    -Z json-target-spec

qemu-system-riscv32 \
    -machine virt -cpu rv32 -m 128M \
    -bios none \
    -nographic \
    -kernel target/riscv32-aruvios/release/aruvios-rv32
```

## Shell Commands

```
$ help           — list all commands
$ ls             — list available utilities
$ echo hello     — print text
$ sum 40 2       — integer addition → 42
$ about          — project information
$ mem 0x10000005 — read MMIO register (e.g., UART LSR)
$ memw <addr> <val> — write to memory address
$ clear          — clear terminal (ANSI escape)
```

## Custom Target: riscv32-aruvios.json

The kernel uses a custom Rust target matching the AruviX processor:
- **ISA**: RV32IM (integer + multiply/divide, no atomics, no compressed)
- **ABI**: ilp32 (32-bit int, long, pointer)
- **No PIE**: Static linking at fixed addresses
- **No atomics**: `max-atomic-width: 0` — matches the hardware

This ensures generated code only uses instructions the AruviX processor supports.

## ISA Compatibility

The AruviX processor (`processor/cpu/cpu_core.v`) implements:
- Full RV32I base integer instructions
- Full RV32M multiply/divide extension
- CSR instructions (CSRRW, CSRRS, CSRRC)
- MRET, EBREAK, ECALL

The kernel is compiled with `+m` feature only, matching exactly what the hardware can execute.

## Roadmap

1. ✅ Boot on QEMU virt with serial shell
2. ⬜ Add interrupt handling (timer, external)
3. ⬜ Add trap dispatch (ecall for syscalls)
4. ⬜ Port to AruviX custom QEMU machine (add UART to aruvix_machine.c)
5. ⬜ Boot on AruviX Verilog simulation (iverilog)
6. ⬜ Boot on FPGA (PYNQ-Z2)
7. ⬜ Add process loading (load programs compiled by AruviX C compiler)
8. ⬜ Run the AruviX JVM as a user program

## File Structure

```
kernel-rv32/
├── Cargo.toml              — Crate config with platform feature flags
├── .cargo/config.toml      — Points to custom riscv32 target
├── riscv32-aruvios.json    — Custom target: RV32IM, no atomics, no PIE
├── build.rs                — Passes linker script to LLD
├── build_rv32.sh           — Build + run script
├── src/
│   ├── boot.S              — Assembly entry: stack setup, BSS zero, call kmain
│   ├── linker.ld           — Links at 0x80000000 (QEMU) with 64KB stack
│   ├── main.rs             — Kernel entry, platform constants, panic handler
│   ├── uart.rs             — Dual UART driver (NS16550A + AruviX custom)
│   └── shell.rs            — Interactive command shell with utilities
└── README.md
```
