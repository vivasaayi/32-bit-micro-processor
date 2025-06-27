# GCC Machine Description for custom32 Architecture

This file defines the processor characteristics for GCC cross-compiler targeting our custom 32-bit RISC processor.

## Register Definitions

```lisp
(define_constants
  [
   (R0_REGNUM 0)
   (R1_REGNUM 1)
   (R30_REGNUM 30)  ; Stack pointer
   (R31_REGNUM 31)  ; Return address register
  ])
```

## Register Classes

```lisp
(define_register_constraint "r" "GENERAL_REGS"
  "General purpose registers R0-R31")

(define_register_constraint "l" "LINK_REG" 
  "Link register R31")
```

## Processor Definition

```lisp
(define_attr "cpu" "custom32"
  (const (symbol_ref "custom32_cpu_attr")))
```

## Instruction Templates

### Arithmetic Operations

```lisp
(define_insn "addsi3"
  [(set (match_operand:SI 0 "register_operand" "=r")
        (plus:SI (match_operand:SI 1 "register_operand" "r")
                 (match_operand:SI 2 "register_operand" "r")))]
  ""
  "ADD %0, %1, %2")

(define_insn "subsi3"  
  [(set (match_operand:SI 0 "register_operand" "=r")
        (minus:SI (match_operand:SI 1 "register_operand" "r")
                  (match_operand:SI 2 "register_operand" "r")))]
  ""
  "SUB %0, %1, %2")

(define_insn "mulsi3"
  [(set (match_operand:SI 0 "register_operand" "=r")
        (mult:SI (match_operand:SI 1 "register_operand" "r")
                 (match_operand:SI 2 "register_operand" "r")))]
  ""
  "MUL %0, %1, %2")
```

### Memory Operations

```lisp
(define_insn "movsi"
  [(set (match_operand:SI 0 "nonimmediate_operand" "=r,m")
        (match_operand:SI 1 "general_operand" "rmi,r"))]
  ""
  "@
   LOADI %0, %1
   LOAD %0, [%1]
   STORE [%0], %1")
```

### Branch Operations

```lisp
(define_insn "beq"
  [(set (pc)
        (if_then_else (eq (match_operand:SI 0 "register_operand" "r")
                         (match_operand:SI 1 "register_operand" "r"))
                     (label_ref (match_operand 2 "" ""))
                     (pc)))]
  ""
  "BEQ %0, %1, %l2")

(define_insn "bne"
  [(set (pc)
        (if_then_else (ne (match_operand:SI 0 "register_operand" "r")
                         (match_operand:SI 1 "register_operand" "r"))
                     (label_ref (match_operand 2 "" ""))
                     (pc)))]
  ""
  "BNE %0, %1, %l2")
```

## Usage with GCC

To use this configuration with a GCC cross-compiler:

1. Copy these patterns into a `.md` file in your GCC build
2. Configure GCC for the custom32 target:
   ```bash
   ../gcc-source/configure --target=custom32-unknown-elf \
     --enable-languages=c --disable-shared --disable-threads \
     --with-newlib --disable-libssp --disable-libgomp
   ```
3. Build the cross-compiler:
   ```bash
   make all-gcc
   make install-gcc
   ```

## Target Specifications

- **Architecture**: custom32
- **ABI**: custom32-unknown-elf
- **Word size**: 32 bits
- **Pointer size**: 32 bits
- **Register file**: 32 × 32-bit registers
- **Calling convention**: 
  - Arguments in R1-R8
  - Return value in R1
  - Stack pointer in R30
  - Link register in R31

## Memory Model

```
Address Space: 32-bit (4GB addressable)
Physical Memory: 1MB (0x00000000-0x000FFFFF)

Sections:
- .text    @ 0x00000000  (Program code)
- .data    @ 0x00010000  (Initialized data)  
- .bss     @ 0x00020000  (Uninitialized data)
- .stack   @ 0x000F0000  (Stack, grows down)
```

This configuration enables GCC to generate assembly code compatible with our custom processor's instruction set and calling conventions.
