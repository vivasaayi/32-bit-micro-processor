# AruviOS: RV32 RISC-V Operating System

## Overview
AruviOS is a minimal operating system kernel for the RV32IM RISC-V architecture, written entirely in Rust. It's designed as the foundation of the AruviX vertical stack, providing a lightweight OS for running user programs on RISC-V hardware, from emulated environments to custom FPGA implementations.

## Architecture

### Core Components
- **Kernel**: Rust no_std implementation compiled to RISC-V ELF using a custom target specification (`riscv32-aruvios.json`)
- **Hardware Platform**: QEMU virt machine emulating RV32IM CPU, 128MB RAM, and NS16550A UART peripherals
- **Shell Interface**: Interactive command-line shell over UART serial communication
- **Utility System**: Currently static built-in Rust functions; designed for future dynamic ELF loading

### Execution Stack
1. Rust source → RISC-V machine code compilation
2. ELF executable loaded by QEMU bootloader
3. Native execution on emulated RISC-V hardware
4. Bidirectional serial I/O via named pipes

### Key Technical Details
- **Target**: Custom RV32IM RISC-V with atomic operations disabled
- **Build System**: Cargo nightly with unstable features
- **Memory Model**: Bare-metal, no standard library dependencies
- **I/O**: UART-based serial communication for user interaction

## Usage

### Prerequisites
- Rust nightly toolchain
- QEMU with RISC-V support
- macOS/Linux development environment

### Building the Kernel
```bash
cd AruviOS/kernel-rv32
./build_rv32.sh build
```

### Running the OS
```bash
./start.sh
```
Launches QEMU with the RV32 kernel and establishes serial communication pipe.

### Interactive Usage
Send commands using the provided script:
```bash
./send_command.sh /tmp/aruvios_serial_<pid> 'echo hello world'
```

### Built-in Commands
- `echo <text>`: Display text output
- `sum <a> <b>`: Integer addition
- `mem <addr>`: Read 32-bit memory location
- `memw <addr> <val>`: Write 32-bit value to memory

## Development Roadmap
- **Short Term**: Implement ELF loader for dynamic user program execution
- **Medium Term**: Port to AruviX FPGA hardware (switch to `aruvix-hw` feature)
- **Long Term**: Full vertical stack integration (AruviJVM → Compiler → OS → FPGA)

## Project Context
AruviOS is part of the AruviX platform, a complete RISC-V vertical stack including:
- Custom RV32I/M microprocessor (FPGA)
- RISC-V assembler and compiler
- JVM interpreter
- Operating system kernel

This project demonstrates end-to-end RISC-V system development, from hardware design to high-level language execution.

---

*Built with Rust for RISC-V | Runs on QEMU | Targets AruviX FPGA*