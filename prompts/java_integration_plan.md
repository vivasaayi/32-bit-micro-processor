# Java Bytecode Interpreter Integration Plan

## Goal
Integrate AruviJVM (Java bytecode interpreter) with the custom 32-bit RISC processor to enable Java program execution.

## Current System Analysis

### Existing Components
1. **AruviJVM**: Complete Java bytecode interpreter in C
   - Located: `/Users/rajanpanneerselvam/work/hdl/AruviJVM/src/`
   - Supports: Basic Java bytecode operations (arithmetic, control flow, method calls)
   - Size: ~355 lines of C code

2. **RISC Processor**: 32-bit custom processor
   - ALU: 16 operations (ADD, SUB, MUL, DIV, logic, shifts, etc.)
   - Instruction Set: ~20 opcodes
   - Memory: Word-addressed with intelligent addressing modes

3. **C Toolchain**: Custom C compiler and assembler
   - C Compiler: Supports subset of C (variables, arithmetic, control flow)
   - Assembler: Translates custom ISA to machine code
   - Test Runner: Automated pipeline for C→ASM→HEX→Simulation

## Required Enhancements

### 1. RISC Instruction Set Extensions

**Analysis**: AruviJVM requires several operations not currently in the ISA:
- **Division and Modulo**: For bytecode operations (IDIV, IREM)
- **Enhanced Shift Operations**: For bytecode optimization
- **Stack Pointer Management**: For JVM stack operations
- **Improved Memory Access**: For heap and stack frame management

**Proposed New Instructions**:
```assembly
# Stack Operations
PUSH Rx         # Push register to stack
POP  Rx         # Pop stack to register
PUSHIMM imm     # Push immediate to stack

# Enhanced Memory
LOADB Rx, addr  # Load byte
STOREB Rx, addr # Store byte
LOADW Rx, addr  # Load word (existing but enhanced)
STOREW Rx, addr # Store word (existing but enhanced)

# Advanced Arithmetic
MOD Rx, Ry, Rz  # Modulo operation
DIVS Rx, Ry, Rz # Signed division

# Stack Frame Management
ENTER imm       # Enter function (allocate stack frame)
LEAVE           # Leave function (deallocate stack frame)
```

### 2. C Compiler Enhancements

**Current Limitations**:
- No struct support (needed for JVM data structures)
- Limited pointer operations
- No dynamic memory allocation
- Missing some C standard library functions

**Required Enhancements**:
- Struct support for `JVM`, `Frame`, `Value` types
- Enhanced pointer arithmetic
- Function pointer support
- Array indexing improvements
- Switch-case statements (for bytecode dispatch)

### 3. Memory Layout for JVM

**Proposed Memory Map**:
```
0x0000-0x1FFF: JVM Code (8KB)
0x2000-0x2FFF: JVM Data/BSS (4KB)
0x3000-0x3FFF: String Log Buffer (4KB) [existing]
0x4000-0x4FFF: JVM Stack (4KB)
0x5000-0x5FFF: JVM Heap (4KB)
0x6000-0x7FFF: Java Bytecode Program (8KB)
0x8000+:       General Program Space [existing]
```

## Implementation Plan

### Phase 1: RISC ISA Enhancement
1. **Add stack operations** to ALU and instruction decoder
2. **Implement modulo operation** in ALU
3. **Add byte-level memory access** to memory controller
4. **Update assembler** to support new instructions
5. **Test enhancements** with simple programs

### Phase 2: C Compiler Enhancement
1. **Add struct support** to lexer/parser
2. **Implement switch-case** for bytecode dispatch
3. **Enhance pointer operations** for JVM data structures
4. **Add function pointer support**
5. **Test with JVM subset**

### Phase 3: JVM Integration
1. **Port AruviJVM source** to use enhanced C compiler
2. **Create JVM program loader** (bytecode → memory)
3. **Implement JVM test runner** similar to existing c_test_runner.py
4. **Test with simple Java programs**

### Phase 4: Java Program Pipeline
1. **Integrate bytecode_converter.py** into build system
2. **Create Java→Bytecode→JVM test pipeline**
3. **Test with existing Java examples**
4. **Demonstrate complete Java execution**

## Risk Assessment

### High Risk
- **C Compiler Complexity**: Adding structs and advanced features is complex
- **Memory Constraints**: JVM + Java program must fit in available memory
- **Performance**: Interpreted Java on interpreted C will be slow

### Medium Risk
- **ISA Changes**: May break existing code (mitigated by careful design)
- **Debugging**: Multiple abstraction layers make debugging difficult

### Low Risk
- **Integration**: Well-defined interfaces between components
- **Testing**: Existing test infrastructure can be extended

## Success Metrics

1. **AruviJVM compiles** with enhanced C compiler
2. **Simple Java program** (e.g., `5 + 3 * 2`) executes correctly
3. **Full pipeline works**: Java → Bytecode → JVM → RISC execution
4. **Performance acceptable**: Under 10 seconds for simple programs
5. **Memory usage**: Under 32KB total (reasonable for FPGA)

## Alternative Approaches

If full JVM integration proves too complex:

1. **Java-to-C Transpiler**: Convert Java to C, then use existing toolchain
2. **Subset JVM**: Implement only integer arithmetic and basic control flow
3. **Bytecode-to-ASM**: Direct bytecode to RISC assembly translation

## Next Steps

1. Begin with Phase 1 (RISC ISA Enhancement)
2. Implement and test new instructions
3. Update assembler and test existing code compatibility
4. Move to Phase 2 (C Compiler Enhancement)

---

*This plan provides a structured approach to achieving Java program execution on the custom RISC processor while managing complexity and risk.*
