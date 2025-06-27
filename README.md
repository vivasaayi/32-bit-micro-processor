# Custom 32-bit RISC Processor Project

A complete hardware description language (HDL) implementation of a custom 32-bit RISC processor with full C toolchain support.

## Quick Start

```bash
# 1. Build the toolchain
cd tools
make

# 2. Test a C program
./temp/c_compiler test_programs/c/basic_test.c
mv test_programs/c/basic_test.asm temp/
./temp/assembler temp/basic_test.asm temp/basic_test.hex

# 3. Run comprehensive tests
./run_tests.sh
```

## Project Structure

```
hdl/
├── tools/                    # Toolchain source and build system
├── temp/                     # Built tools and generated files  
├── test_programs/           # Test programs and examples
│   ├── c/                   # C programs
│   └── assembly/            # Assembly programs
├── processor/               # Complete processor HDL implementation
│   ├── cpu/                 # CPU core modules
│   │   ├── cpu_core.v      # Main CPU core
│   │   ├── alu.v           # 32-bit ALU
│   │   └── register_file.v # 32-bit register file
│   ├── memory/             # Memory system modules
│   ├── io/                 # I/O and peripheral modules
│   ├── testbench/          # Simulation testbenches
│   └── microprocessor_system.v # Top-level processor system
├── docs/                   # Documentation
├── run_tests.sh           # Test runner
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
