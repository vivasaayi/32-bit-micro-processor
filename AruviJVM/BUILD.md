# AruviJVM Build and Test Guide

## Quick Start

1. **Build the interpreter:**
   ```bash
   cd /Users/rajanpanneerselvam/work/AruviJVM
   make all
   ```

2. **Run the built-in tests:**
   ```bash
   make run
   ```

3. **Clean build files:**
   ```bash
   make clean
   ```

## Project Structure

```
AruviJVM/
├── src/                    # Source code
│   ├── jvm.h              # JVM core definitions
│   ├── jvm.c              # JVM implementation
│   ├── main.c             # Test programs and main function
│   ├── bytecode_loader.h  # Bytecode file I/O (future)
│   └── bytecode_loader.c  # Bytecode file I/O implementation
├── examples/              # Java example programs
│   ├── JavaExamples.java  # Collection of example algorithms
│   ├── SimpleTest.java    # Simple test program
│   └── Variables.java     # Variable manipulation example
├── tools/                 # Development tools
│   └── bytecode_converter.py  # Convert javap output to C arrays
├── Makefile              # Build configuration
└── README.md             # Main documentation
```

## Building for Different Targets

### Native Build (macOS/Linux)
```bash
make all
```

### Cross-compilation for RISC-V
```bash
# Requires riscv64-linux-gnu-gcc
make riscv
```

### Manual Compilation
```bash
gcc -Wall -Wextra -std=c99 -O2 src/jvm.c src/main.c -o aruvijvm
```

## Running Tests

The interpreter includes several built-in tests:

1. **Arithmetic Test**: Computes `5 + 3 * 2 = 11`
2. **Local Variables Test**: Stores and loads values: `42 + 10 = 52`
3. **Conditional Branch Test**: Tests `10 > 5` (returns 1 for true)
4. **Simple Counting Test**: Incremental counting operations

Expected output:
```
AruviJVM - Simple Java Bytecode Interpreter
===========================================

=== Running test: Arithmetic (5 + 3 * 2) ===
Executing bytecode...
Method returned: 11
Test result: 11

=== Running test: Local Variables (42 + 10) ===
Executing bytecode...
Method returned: 52
Test result: 52

=== Running test: Conditional Branch (10 > 5) ===
Executing bytecode...
Method returned: 1
Test result: 1

=== Running test: Simple Counting (1+1+1) ===
Executing bytecode...
Method returned: 3
Test result: 3
```

## Working with Java Bytecode

### Compiling Java Source
```bash
cd examples/
javac SimpleTest.java
javap -c SimpleTest
```

### Converting Bytecode
```bash
# Generate bytecode listing
javap -c SimpleTest > bytecode.txt

# Convert to AruviJVM format
python3 tools/bytecode_converter.py bytecode.txt
```

## Supported Java Bytecode Instructions

### Constants
- `iconst_m1` through `iconst_5` - Load integer constants
- `bipush <value>` - Push byte value as integer
- `sipush <value>` - Push short value as integer

### Local Variables
- `iload <index>`, `iload_0` to `iload_3` - Load integer from local variable
- `istore <index>`, `istore_0` to `istore_3` - Store integer to local variable

### Stack Operations
- Basic stack manipulation for integer values

### Arithmetic
- `iadd` - Integer addition
- `isub` - Integer subtraction  
- `imul` - Integer multiplication
- `idiv` - Integer division
- `irem` - Integer remainder (modulo)
- `ineg` - Integer negation

### Control Flow
- `if_icmpeq`, `if_icmpne` - Integer equality/inequality comparison
- `if_icmplt`, `if_icmpge` - Integer less than/greater than or equal
- `if_icmpgt`, `if_icmple` - Integer greater than/less than or equal
- `goto <offset>` - Unconditional jump

### Method Return
- `ireturn` - Return integer value
- `return` - Return void
- `halt` - Stop execution (AruviJVM extension)

## Memory Layout

### Stack
- Operand stack: 1024 entries
- Each entry holds a 32-bit signed integer

### Local Variables
- 256 local variable slots per method frame
- Currently supports integers only

### Heap
- Simple linear heap: 8KB
- Reserved for future object allocation

## Error Handling

The interpreter provides basic error detection for:
- Stack overflow/underflow
- Division by zero
- Invalid opcodes
- Out of bounds memory access

## Debugging

### Enable Debug Mode
Debug mode can be enabled by modifying the source code:
```c
jvm_set_debug(jvm, 1);  // Enable debug output
```

### Bytecode Disassembly
The interpreter includes a disassembler for educational purposes:
```c
disassemble(bytecode, length);
```

## Performance Characteristics

This interpreter prioritizes:
1. **Simplicity** over performance
2. **Portability** over optimization
3. **Educational value** over completeness

Expected performance:
- ~1M instructions per second on modern hardware
- Suitable for embedded control applications
- Not optimized for compute-intensive tasks

## RISC-V Considerations

### Cross-compilation
```bash
# Install RISC-V toolchain (Ubuntu/Debian)
sudo apt-get install gcc-riscv64-linux-gnu

# Build for RISC-V
make riscv
```

### Memory Constraints
The interpreter is designed to work within typical embedded constraints:
- ~10KB code size
- ~10KB RAM usage
- No dynamic memory allocation after initialization

### Future RISC-V Optimizations
- Custom instruction extensions for JVM operations
- Optimized calling conventions
- Hardware accelerated stack operations

## Troubleshooting

### Compilation Issues
- Ensure C99 compiler support
- Check that all source files are present
- Verify include paths are correct

### Runtime Issues
- Check stack overflow/underflow messages
- Verify bytecode format and opcodes
- Enable debug mode for detailed execution traces

### Cross-compilation Issues
- Verify RISC-V toolchain installation
- Check static linking for standalone executables
- Test on RISC-V emulator before hardware deployment

## Extension Points

The architecture supports easy extension:

1. **New Data Types**: Modify Value struct and add type checking
2. **New Instructions**: Add opcodes to enum and implement in switch statement
3. **Object Support**: Extend heap management and add reference types
4. **I/O Operations**: Add system call interface for embedded systems
5. **JIT Compilation**: Replace interpreter loop with code generation

## Contributing

When adding features:
1. Maintain C99 compatibility
2. Keep code simple and readable
3. Add corresponding test cases
4. Update documentation
5. Ensure RISC-V cross-compilation still works
