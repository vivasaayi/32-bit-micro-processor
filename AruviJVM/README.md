# AruviJVM - Simple Java Bytecode Interpreter

A minimal Java bytecode interpreter written in C, designed to run on RISC-V systems and use only basic C constructs for portability.

## Overview

AruviJVM is a simple Java Virtual Machine implementation focused on:
- Basic arithmetic operations
- Local variables and stack operations
- Conditional branching
- Simple loops
- Integer data types only (to start with)

This interpreter is designed to be simple enough to compile with basic C compilers and eventually run on RISC-V hardware.

## Features

### Supported Bytecode Instructions

**Constants:**
- `iconst_m1`, `iconst_0` through `iconst_5` - Load integer constants
- `bipush` - Push byte as integer
- `sipush` - Push short as integer

**Local Variables:**
- `iload`, `iload_0` through `iload_3` - Load integer from local variable
- `istore`, `istore_0` through `istore_3` - Store integer to local variable

**Arithmetic:**
- `iadd` - Integer addition
- `isub` - Integer subtraction
- `imul` - Integer multiplication
- `idiv` - Integer division
- `irem` - Integer remainder
- `ineg` - Integer negation

**Control Flow:**
- `if_icmpeq`, `if_icmpne`, `if_icmplt`, `if_icmpge`, `if_icmpgt`, `if_icmple` - Integer comparisons
- `goto` - Unconditional jump

**Method Control:**
- `ireturn` - Return integer value
- `return` - Return void
- `halt` - Stop execution (custom instruction)

## Building

### Prerequisites
- GCC or any C99-compatible compiler
- Make (optional, but recommended)

### Compilation

Using Make:
```bash
make all       # Build the interpreter
make run       # Build and run tests
make clean     # Clean build files
```

Manual compilation:
```bash
gcc -Wall -Wextra -std=c99 -O2 src/*.c -o aruvijvm
```

### Cross-compilation for RISC-V

If you have a RISC-V cross-compiler installed:
```bash
make riscv
```

Or manually:
```bash
riscv64-linux-gnu-gcc -Wall -Wextra -std=c99 -O2 -static src/*.c -o aruvijvm-riscv
```

## Usage

The interpreter currently runs built-in test programs that demonstrate:

1. **Arithmetic Test**: Computes `5 + 3 * 2 = 11`
2. **Local Variables Test**: Stores values in locals and adds them
3. **Conditional Branch Test**: Tests if `10 > 5`
4. **Simple Loop Test**: Sums numbers from 1 to 5

Run the interpreter:
```bash
./aruvijvm
```

## Project Structure

```
AruviJVM/
├── src/
│   ├── jvm.h           # JVM data structures and function declarations
│   ├── jvm.c           # JVM implementation and bytecode interpreter
│   └── main.c          # Test programs and main function
├── Makefile            # Build configuration
└── README.md           # This file
```

## Architecture

### JVM Structure
- **Operand Stack**: 1024 entries for intermediate values
- **Local Variables**: 256 slots per method frame
- **Call Stack**: 256 frames for method calls
- **Simple Heap**: 8KB for future object allocation

### Value System
Currently supports only 32-bit signed integers. The design allows for easy extension to other types.

### Execution Model
- Stack-based virtual machine
- Single-threaded execution
- Simple memory management

## Design Principles

1. **Simplicity**: Uses only basic C constructs (no advanced features)
2. **Portability**: Designed to compile with minimal C compilers
3. **Educational**: Code is well-commented and easy to understand
4. **Extensible**: Architecture allows for easy addition of new features

## Future Enhancements

### Planned Features
- [ ] More data types (long, float, references)
- [ ] Arrays and basic objects
- [ ] Method calls and stack frames
- [ ] Basic class loading
- [ ] Simple garbage collection
- [ ] I/O operations for embedded systems

### RISC-V Optimization
- [ ] RISC-V assembly optimizations for critical paths
- [ ] Memory layout optimizations
- [ ] Interrupt handling for embedded use

## Example Usage

Here's how the arithmetic test works:

```java
// Equivalent Java code:
// return 5 + 3 * 2;

// Bytecode:
iconst_5    // Push 5
iconst_3    // Push 3  
iconst_2    // Push 2
imul        // 3 * 2 = 6
iadd        // 5 + 6 = 11  
ireturn     // Return 11
```

## Contributing

This is a learning project focused on understanding JVM internals and embedded systems programming. Contributions should maintain the simplicity and educational value of the codebase.

## License

This project is educational and meant for learning purposes. Feel free to use and modify as needed for your own projects.
# AruviJVM
