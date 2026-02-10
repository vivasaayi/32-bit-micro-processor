# HDL Processor Tools

This directory contains the complete toolchain for developing programs for our custom 32-bit RISC processor.

## Project Structure

```
hdl/
├── tools/                    # Toolchain source code and build system
│   ├── c_compiler.c         # C-to-assembly compiler (source)
│   ├── assembler.c          # Assembly-to-hex converter (source)
│   ├── Makefile             # Build system
│   └── README.md            # This file
├── temp/                     # All generated files and built tools
│   ├── c_compiler           # Built C compiler
│   ├── assembler            # Built assembler
│   ├── *.asm               # Generated assembly files
│   └── *.hex               # Generated hex files
├── test_programs/           # Test programs and examples
│   ├── c/                   # C test programs
│   │   ├── basic_test.c
│   │   ├── math_test.c
│   │   └── ...
│   └── assembly/            # Assembly test programs
│       ├── hello_world.asm
│       ├── sort_demo.asm
│       └── ...
└── run_tests.sh            # Comprehensive test runner
```

## Architecture Specification

- **Name**: custom32 
- **Word size**: 32-bit
- **Registers**: 32 general-purpose registers (R0-R31)
- **Endianness**: Little-endian
- **Stack**: Grows downward from 0x000F0000
- **Memory**: 1MB internal (0x00000000-0x000FFFFF)

## Available Tools

### 1. C Compiler (`c_compiler`)
A custom C-to-assembly compiler written in C that supports:
- Basic C syntax (variables, functions, control flow)
- Pointers and dereferencing
- Arrays and string literals
- Logical and arithmetic operators
- Memory allocation via static pool

```bash
# Compile C source to assembly
./c_compiler input.c output.asm
```

### 2. Assembler (`assembler`)
Converts assembly code to machine code hex format.

```bash
# Assemble to hex format
./assembler input.asm output.hex
```

### 3. Legacy Python C Compiler (`c_compiler.py`)
The original Python implementation of the C compiler (deprecated, use C version).


### 4. Custom Educational Emulator (`custom_qemu_emulator`)
A small, readable emulator for the custom 32-bit assembly dialect used in this repo.

```bash
cd tools/custom_qemu_emulator
python3 emulator.py ../../test_programs/assembly/0_9_0_simple_store_test.asm
```

This is useful for understanding instruction semantics and comparing behavior with QEMU/RTL.

## Instruction Set

The processor supports the following instruction format:

```
ADD Rd, Rs, Rt     ; Rd = Rs + Rt
SUB Rd, Rs, Rt     ; Rd = Rs - Rt  
MUL Rd, Rs, Rt     ; Rd = Rs * Rt
DIV Rd, Rs, Rt     ; Rd = Rs / Rt
LOADI Rd, #imm     ; Rd = immediate value
LOAD Rd, [Rs]      ; Rd = memory[Rs]
STORE [Rd], Rs     ; memory[Rd] = Rs
BEQ Rs, Rt, label  ; Branch if Rs == Rt
BNE Rs, Rt, label  ; Branch if Rs != Rt
JMP label          ; Unconditional jump
CALL label         ; Function call
RET                ; Return from function
HALT               ; Stop execution
```

## Memory Layout

```
0x00000000 - 0x0000FFFF: Program memory (64KB)
0x00010000 - 0x0001FFFF: Data memory (64KB)
0x00020000 - 0x000EFFFF: Heap space (832KB)
0x000F0000 - 0x000FFFFF: Stack (64KB, grows downward)
```

## Build Instructions

```bash
# Build all tools (they will be placed in ../temp/)
cd tools
make

# Build specific tool
make c_compiler    # Builds ../temp/c_compiler
make assembler     # Builds ../temp/assembler

# Clean build artifacts
make clean

# Test tools
make test
```

## Usage Examples

### Building Tools
```bash
cd tools
make                    # Build everything
```

### Compiling C Programs
```bash
# Compile C program to assembly
./temp/c_compiler test_programs/c/program.c

# The assembly output will be in test_programs/c/program.asm
# Move it to temp for further processing:
mv test_programs/c/program.asm temp/

# Assemble to hex
./temp/assembler temp/program.asm temp/program.hex
```

### Testing Programs
```bash
# Test all programs (C and assembly)
./run_tests.sh

# Test only C programs  
./run_tests.sh c

# Test only assembly programs
./run_tests.sh a
```

### C Program Requirements

C programs must write their exit status to memory address `0x2000`:
- `0x00000001`: Success/Pass
- `0x00000000`: Failure/Error

Example:
```c
int main() {
    int result = compute_something();
    
    // Write status to 0x2000
    int *status = (int*)0x2000;
    *status = (result == expected) ? 1 : 0;
    
    return 0;
}
```

## Supported C Features

- **Data types**: int, char, pointers, arrays
- **Operators**: +, -, *, /, ==, !=, <, >, <=, >=, &&, ||, !
- **Control flow**: if/else, while, for
- **Functions**: definition, calls, return values
- **Memory**: static allocation, simple malloc from pool
- **Pointers**: dereferencing (*), address-of (&)

## Limitations

- No dynamic memory allocation (malloc/free) beyond static pool
- No structs or unions
- No function pointers
- Limited standard library support
- No floating-point arithmetic

## File Organization

- `tools/c_compiler.c` - C compiler source code
- `tools/assembler.c` - Assembler source code  
- `tools/Makefile` - Build configuration
- `tools/README.md` - This documentation
- `temp/c_compiler` - Built C compiler binary
- `temp/assembler` - Built assembler binary
- `test_programs/c/` - C test programs and examples
- `test_programs/assembly/` - Assembly test programs and examples
- `run_tests.sh` - Comprehensive test runner

## GCC Cross-Compiler Configuration

For advanced users, GCC machine description patterns for custom32:

```lisp
;; Example instruction pattern
(define_insn "addsi3"
  [(set (match_operand:SI 0 "register_operand" "=r")
        (plus:SI (match_operand:SI 1 "register_operand" "r")
                 (match_operand:SI 2 "register_operand" "r")))]
  ""
  "ADD %0, %1, %2")
```

Register constraints:
- `"r"`: General purpose registers R0-R31
- `"l"`: Link register R31
- Stack pointer: R30
