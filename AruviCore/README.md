# HDL Processor Implementation

This directory contains the complete Verilog implementation of the custom 32-bit RISC processor.

## Directory Structure

```
processor/
├── README.md                    # This file
├── microprocessor_system.v      # Top-level processor system
├── cpu/                         # CPU core modules
│   ├── cpu_core.v              # Main CPU core implementation
│   ├── alu.v                   # Arithmetic Logic Unit
│   └── register_file.v         # Register file implementation
├── memory/                      # Memory system modules
│   ├── memory_controller.v     # Memory controller
│   └── mmu.v                   # Memory Management Unit
├── io/                         # I/O and peripheral modules
│   ├── uart.v                  # UART communication
│   ├── uart_simple.v           # Simplified UART
│   ├── timer.v                 # Timer/counter module
│   └── interrupt_controller.v  # Interrupt handling
└── testbench/                  # Simulation testbenches
    ├── tb_microprocessor_system.v  # Main system testbench
    ├── microprocessor_system.vvp   # Compiled simulation
    └── simple_sort.hex             # Test program
```

## Module Hierarchy

### Top Level
- **`microprocessor_system.v`** - Complete processor system integrating all components

### CPU Core (`cpu/`)
- **`cpu_core.v`** - Main processor core with instruction fetch, decode, execute pipeline
- **`alu.v`** - 32-bit Arithmetic Logic Unit supporting all processor operations
- **`register_file.v`** - 32 × 32-bit general-purpose register file

### Memory System (`memory/`)
- **`memory_controller.v`** - Handles memory access and timing
- **`mmu.v`** - Memory Management Unit (if implemented)

### I/O System (`io/`)
- **`uart.v`** - Full UART implementation for serial communication
- **`uart_simple.v`** - Simplified UART for basic I/O
- **`timer.v`** - Timer/counter with interrupt capability
- **`interrupt_controller.v`** - Central interrupt management

### Testbenches (`testbench/`)
- **`tb_microprocessor_system.v`** - Main system testbench for simulation
- **`*.vvp`** - Compiled simulation files
- **`*.hex`** - Test programs in hex format

## Processor Specifications

### Architecture
- **32-bit RISC architecture**
- **32 general-purpose registers** (R0-R31)
- **Harvard architecture** (separate instruction and data paths)
- **Memory-mapped I/O**

### Features
- **Full 32-bit data path**
- **Rich instruction set** (arithmetic, logical, memory, control)
- **Hardware stack support** (R30 = stack pointer, R31 = link register)
- **Interrupt support** via interrupt controller
- **UART communication** for external interface
- **Timer functionality** for time-based operations

### Memory Layout
```
0x00000000 - 0x0000FFFF: Program memory (64KB)
0x00010000 - 0x0001FFFF: Data memory (64KB)
0x00020000 - 0x000EFFFF: Heap space (832KB)
0x000F0000 - 0x000FFFFF: Stack (64KB, grows downward)
0xF0000000 - 0xFFFFFFFF: Memory-mapped I/O
```

## Building and Simulation

### Using Icarus Verilog
```bash
# Compile the processor system
cd processor
iverilog -o testbench/microprocessor_system.vvp \
    testbench/tb_microprocessor_system.v \
    microprocessor_system.v \
    cpu/*.v memory/*.v io/*.v

# Run simulation with a test program
vvp testbench/microprocessor_system.vvp +hex_file=../temp/program.hex

# View waveforms (if VCD dumping is enabled)
gtkwave testbench/microprocessor_system.vcd
```

### Integration with Toolchain
```bash
# Compile C program and simulate
cd ..
./temp/c_compiler test_programs/c/program.c
mv test_programs/c/program.asm temp/
./temp/assembler temp/program.asm temp/program.hex

# Run on processor
cd processor
vvp testbench/microprocessor_system.vvp +hex_file=../temp/program.hex
```

## Design Notes

### CPU Core
- Implements a simple state machine for instruction execution
- Supports all arithmetic, logical, memory, and control operations
- Register R0 is hardwired to zero (RISC convention)
- Stack operations use R30 (stack pointer) and R31 (link register)

### Memory System
- Synchronous memory interface
- Separate instruction and data memory spaces
- Memory controller handles timing and access control

### I/O System
- Memory-mapped I/O for peripheral access
- Interrupt-driven I/O supported via interrupt controller
- UART for communication with external systems

### Testbench
- Supports dynamic hex file loading via command line
- Status reporting at memory address 0x2000
- Configurable simulation timeout and cycle counting

## Adding New Modules

When adding new processor modules:

1. **Place in appropriate subdirectory**:
   - CPU-related: `cpu/`
   - Memory-related: `memory/`
   - I/O-related: `io/`

2. **Update integration**:
   - Add to `microprocessor_system.v` if needed
   - Update testbench if testing required

3. **Follow naming conventions**:
   - Use lowercase with underscores: `module_name.v`
   - Clear, descriptive module names

4. **Document**:
   - Add module description to this README
   - Include inline comments in Verilog code

## Testing

The processor can be tested with:
- **C programs** compiled via the toolchain
- **Assembly programs** written directly
- **Unit tests** for individual modules
- **Integration tests** via the main testbench

All test programs should write their status to memory address `0x2000`:
- `0x00000001` = Success/Pass
- `0x00000000` = Failure/Error

## FPGA Deployment

The processor is designed for FPGA deployment with:
- **Synchronous design** using single clock domain
- **Standard Verilog** compatible with most synthesis tools
- **Parameterizable** memory sizes and features
- **Clean hierarchy** for easy integration

For FPGA deployment:
1. Synthesize using your FPGA vendor's tools
2. Constrain clock and I/O pins appropriately
3. Initialize memory with your program hex files
4. Connect UART to external pins for communication

---

This processor implementation provides a complete, working 32-bit RISC processor suitable for educational use, FPGA deployment, and further development.
