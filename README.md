# 32-Bit HDL Microprocessor

A complete 32-bit microprocessor implementation in Verilog, ready for FPGA deployment.

## Features

- **32-bit Architecture**: 4GB address space with 32-bit data path
- **RISC-like Instruction Set**: Clean, orthogonal instruction set with 32-bit instructions
- **16 32-bit Registers**: General-purpose register file (R0-R15)
- **Advanced ALU**: 32-bit arithmetic and logic operations with flag generation
- **Memory System**: 64KB internal memory with external expansion capability
- **Pipeline Design**: 5-stage state machine for efficient execution
- **FPGA Ready**: Standard Verilog with proper synchronous design

## Quick Start

```bash
# Build and run simulation
make sim

# Assemble a program
make assemble

# View waveforms (requires GTKWave)
make wave

# Clean build files
make clean
```

## Project Structure

```
hdl/
├── cpu/                    # 32-bit CPU components
│   ├── cpu_core_32_simple.v   # Main CPU core
│   ├── alu_32.v               # 32-bit ALU
│   └── register_file_32.v     # 32-bit register file
├── examples_32/            # 32-bit assembly programs
│   └── simple_sort_32.asm     # Bubble sort demonstration
├── testbench_32/          # 32-bit test benches
│   └── tb_microprocessor_32.v # System testbench
├── tools/                  # Development tools
│   └── assembler_32.py        # 32-bit assembler
├── microprocessor_system_32.v # Top-level system
├── Makefile               # Build system
└── legacy_8bit/           # Previous 8-bit implementation
```

## Memory Map
- `0x0000-0x7FFF`: User space (32KB)
- `0x8000-0xEFFF`: Kernel space (28KB)
- `0xF000-0xF0FF`: I/O mapped peripherals
- `0xF100-0xFFFF`: System ROM/Boot loader

## Building and Testing
1. Install Icarus Verilog: `brew install icarus-verilog`
2. Run simulation: `make sim`
3. Run tests: `make test`
4. Synthesize: `make synth`

## Linux Compatibility
While this is an 8-bit processor, it includes features necessary for a minimal Linux-like system:
- Virtual memory management
- User/kernel mode separation
- System calls
- Basic I/O
- Timer interrupts

Note: This will be a severely limited Linux implementation, more like a microkernel.
# micro-processor
