# 8-Bit Microprocessor Design

## Overview
This project implements an 8-bit microprocessor capable of running a basic Linux-like system. The processor features:

- 8-bit data bus
- 16-bit address bus (64KB addressable memory)
- RISC-like instruction set
- Von Neumann architecture
- Basic I/O capabilities
- Memory management unit (MMU) for virtual memory
- Interrupt handling

## Architecture Components

### Core Components
- **CPU Core** (`cpu/cpu_core.v`) - Main processing unit
- **ALU** (`cpu/alu.v`) - Arithmetic and Logic Unit
- **Register File** (`cpu/register_file.v`) - General purpose registers
- **Control Unit** (`cpu/control_unit.v`) - Instruction decode and control
- **Memory Interface** (`memory/memory_controller.v`) - Memory access controller
- **MMU** (`memory/mmu.v`) - Memory Management Unit
- **Cache** (`memory/cache.v`) - Simple cache implementation

### I/O and Peripherals
- **UART** (`io/uart.v`) - Serial communication
- **Timer** (`io/timer.v`) - System timer
- **Interrupt Controller** (`io/interrupt_controller.v`) - Handles interrupts
- **GPIO** (`io/gpio.v`) - General purpose I/O

### System Components
- **Bus Controller** (`system/bus_controller.v`) - System bus management
- **Clock Manager** (`system/clock_manager.v`) - Clock generation and management

## Instruction Set Architecture (ISA)

### Registers
- **R0-R7**: General purpose registers (8-bit each)
- **SP**: Stack Pointer (16-bit)
- **PC**: Program Counter (16-bit)
- **FLAGS**: Status flags (8-bit)

### Instruction Format
- **Type 1**: `[OPCODE:4][REG:3][IMM:1]` - Register/Immediate operations
- **Type 2**: `[OPCODE:4][REG1:2][REG2:2]` - Register-to-register operations
- **Type 3**: `[OPCODE:8]` - Control flow operations

### Instruction Set
See `docs/instruction_set.md` for complete ISA documentation.

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
