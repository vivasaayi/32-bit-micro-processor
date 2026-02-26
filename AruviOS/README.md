# AruviOS - Hobby Operating System

A self-contained operating system project with support for **RV32 RISC-V** architecture, featuring a **simple shell**, **utility registry**, and interactive command execution.

## Current Status

- ✅ **RV32 Kernel**: Fully functional on QEMU virt machine
- ✅ **Interactive Shell**: UART-based command interface
- ✅ **QEMU Testing**: Cross-platform development environment
- 🔄 **AruviX Hardware**: Ready for FPGA deployment

## Architecture

Currently supports:
- **RV32IM ISA** (RV32I + Integer Multiplication/Division)
- **QEMU virt machine** for development/testing
- **AruviX custom RISC processor** for hardware deployment
- **UART serial I/O** for user interaction
- **Simple shell** with built-in utilities

## Quick Start (RV32)

```bash
cd kernel-rv32
./build_rv32.sh build    # Build the kernel
./start.sh               # Launch interactive session
```

From another terminal, send commands:
```bash
./send_command.sh /tmp/aruvios_serial_XXXXX help
./send_command.sh /tmp/aruvios_serial_XXXXX "echo hello world"
```

## Folder structure

```
AruviOS/
├── kernel-rv32/                 # RV32 RISC-V kernel
│   ├── build_rv32.sh           # Build script
│   ├── start.sh                # Interactive launcher
│   ├── send_command.sh         # Command sender utility
│   ├── riscv32-aruvios.json    # Custom Rust target
│   └── src/
│       ├── main.rs             # Kernel entrypoint
│       ├── uart.rs             # UART driver
│       ├── shell.rs            # Interactive shell
│       └── boot.S              # Assembly bootstrap
├── programs/                   # Sample applications
├── scripts/                    # Build utilities
├── docs/                       # Documentation
└── tests/                      # Test suites
```
│       ├── shell.rs             # Simple shell + command parsing
│       ├── keyboard.rs          # PS/2 scancode input
│       └── vga.rs               # VGA text output
├── programs/
│   ├── c/                        # Sample host-side C utilities
│   └── asm/                      # Sample host-side ASM utility
├── scripts/
│   ├── create_vdi.sh            # VirtualBox VDI conversion helper
│   └── test_terminal.py          # QEMU serial smoke test runner
├── tests/
│   └── test_cases.md             # Documented test scenarios
└── user_utils/
    └── src/
        ├── echo.c               # Example C utility skeleton
        └── sum.c                # Example C utility skeleton
```

## What this already does

- Boots to VGA text mode.
- Prints a shell prompt.
- Accepts keyboard input.
- Supports:
  - `help`
  - `ls` (lists registered utilities)
  - `run <utility> [args]`
  - `clear`
- Includes registered demo utilities:
  - `echo`
  - `sum`
  - `about`

## Build and run

```bash
cd hobby_os
make image
make run
make bundle-programs
```


## Test workflow

```bash
cd hobby_os
make test-programs   # checks C/ASM sample utilities
make test-terminal   # boots QEMU and validates shell behavior
make test            # full test suite
```

## Run in VirtualBox

1. Build image (`make image`).
2. Convert raw image to VDI:
   ```bash
   make vdi
   # or manually:
   VBoxManage convertfromraw ../kernel/target/x86_64-unknown-none/debug/bootimage-aruvix_hobby_os.bin hobby_os.vdi --format VDI
   ```
3. Create VM (Other/Unknown OS).
4. Attach `hobby_os.vdi` as primary disk.
5. Boot VM.

## Readiness (important)

This repo currently provides a DOS-like shell experience, but **external program execution is not complete yet**.

Run:

```bash
make readiness
```

for an exact requirement-by-requirement status and missing pieces.

## Next milestone for C utilities

Right now utility execution is in-kernel Rust function dispatch. The next step is:

1. Define a tiny utility ABI (`int main(int argc, char** argv)` style).
2. Compile C utilities into flat binaries.
3. Add a tiny in-memory filesystem or ROM loader.
4. Extend `run` to load binary utility image and jump to entrypoint in user mode.

This gives the full cycle you asked for: list utilities, execute utilities, and keep extending toward a small but real OS.
