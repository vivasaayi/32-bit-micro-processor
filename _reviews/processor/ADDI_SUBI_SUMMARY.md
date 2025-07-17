# ADDI and SUBI Instruction Implementation Summary

## Overview
Successfully implemented and tested the ADDI (Add Immediate) and SUBI (Subtract Immediate) instructions for the RISC processor. These instructions allow adding or subtracting an immediate constant value to/from a register.

## Implementation Details

### Instruction Format
Both instructions use the same format:
```
[31:26] - Opcode (6 bits)
[25:21] - Destination register (rd)
[20:16] - Source register (rs1)
[15:9]  - Reserved/unused
[8:0]   - 9-bit signed immediate value
```

### Opcodes
- **ADDI**: 0x0D (13 decimal)
- **SUBI**: 0x0E (14 decimal)

### CPU Implementation
1. **ALU Module**: Added cases for ALU_ADDI and ALU_SUBI operations
2. **Immediate Decoding**: Fixed sign extension logic for 9-bit immediate values
   - Original (buggy): `{{23{imm12[8]}}, imm12}` - included bit 8 twice
   - Fixed: `{{23{imm12[8]}}, imm12[7:0]}` - proper sign extension

### Assembler Support
1. **Pattern Recognition**: Added regex patterns for ADDI and SUBI instructions
2. **Instruction Encoding**: Proper encoding of opcode, registers, and immediate values
3. **Immediate Handling**: Support for both positive and negative immediate values

## Test Results

### ADDI Test Program
```assembly
LOADI R1, #10      ; Load 10 into R1
ADDI R2, R1, #5    ; R2 = R1 + 5 = 15
ADDI R3, R2, #-3   ; R3 = R2 + (-3) = 12
ADDI R4, R0, #42   ; R4 = R0 + 42 = 42
ADDI R5, R0, #255  ; R5 = R0 + 255 = 255
```

**Results**: ✅ All operations executed correctly
- R1 = 10
- R2 = 15 
- R3 = 12
- R4 = 42
- R5 = 255

### SUBI Test Program
```assembly
LOADI R1, #20      ; Load 20 into R1
SUBI R2, R1, #5    ; R2 = R1 - 5 = 15
SUBI R3, R2, #10   ; R3 = R2 - 10 = 5
SUBI R4, R1, #0    ; R4 = R1 - 0 = 20
```

**Results**: ✅ All operations executed correctly
- R1 = 20
- R2 = 15
- R3 = 5
- R4 = 20

## Key Technical Fixes

### 1. Sign Extension Bug Fix
**Problem**: The original implementation included the sign bit (bit 8) twice in the sign extension:
```verilog
{{23{imm12[8]}}, imm12}  // WRONG - bit 8 counted twice
```

**Solution**: Properly separate sign extension from data bits:
```verilog
{{23{imm12[8]}}, imm12[7:0]}  // CORRECT - sign extend bit 8, use bits [7:0] for data
```

### 2. Immediate Range
- 9-bit signed immediate values
- Range: -256 to +255
- Two's complement representation

### 3. Assembly Syntax
- **ADDI**: `ADDI Rd, Rs1, #immediate`
- **SUBI**: `SUBI Rd, Rs1, #immediate`
- Immediate values can be positive or negative
- Hash (#) prefix required for immediate values

## Verification
- Both positive and negative immediate values work correctly
- Sign extension properly handles negative values
- ALU performs arithmetic correctly
- Register writes occur as expected
- No timing or control flow issues observed

## Integration Status
✅ Fully integrated into:
- CPU core (cpu_core.v)
- ALU module (alu.v)
- Assembler (assembler.c)
- Test framework

The ADDI and SUBI instructions are now fully functional and ready for use in larger programs.
