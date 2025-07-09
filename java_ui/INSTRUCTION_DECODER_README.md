# Instruction Decoder Tab

## Overview
The Instruction Decoder tab allows you to decode 32-bit instructions for your custom CPU. It supports both hexadecimal and binary input formats and provides a detailed breakdown of instruction fields.

## Features

### Input Formats
- **Hexadecimal**: `0x12345678` or `12345678`
- **Binary**: `11010001001000101100111110001000` (up to 32 bits)

### Instruction Fields (32-bit format)
- **Opcode** (bits 31:26): 6-bit operation code
- **RD** (bits 23:19): 5-bit destination register
- **RS1** (bits 18:14): 5-bit source register 1
- **RS2** (bits 13:9): 5-bit source register 2
- **IMM[18:0]** (bits 18:0): 19-bit immediate value
- **IMM[8:0]** (bits 8:0): 9-bit immediate value

### Supported Opcodes

#### ALU Operations (0x00–0x1F)
- 0x00: ADD - Addition
- 0x01: SUB - Subtraction
- 0x02: AND - Bitwise AND
- 0x03: OR - Bitwise OR
- 0x04: XOR - Bitwise XOR
- 0x05: NOT - Bitwise NOT
- 0x06: SHL - Shift Left
- 0x07: SHR - Shift Right
- 0x08: MUL - Multiplication
- 0x09: DIV - Division
- 0x0A: MOD - Modulo
- 0x0B: CMP - Compare
- 0x0C: SAR - Arithmetic Shift Right

#### Memory Operations (0x20–0x2F)
- 0x20: LOAD - Load from memory
- 0x21: STORE - Store to memory

#### Control/Branch Operations (0x30–0x3F)
- 0x30: JMP - Unconditional jump
- 0x31: JZ - Jump if zero
- 0x32: JNZ - Jump if not zero
- 0x33: JC - Jump if carry
- 0x34: JNC - Jump if not carry
- 0x35: JLT - Jump if less than
- 0x36: JGE - Jump if greater/equal
- 0x37: JLE - Jump if less/equal
- 0x38: CALL - Call subroutine
- 0x39: RET - Return from subroutine
- 0x3A: PUSH - Push to stack
- 0x3B: POP - Pop from stack

#### Set/Compare Operations (0x40–0x4F)
- 0x40: SETEQ - Set if equal
- 0x41: SETNE - Set if not equal
- 0x42: SETLT - Set if less than
- 0x43: SETGE - Set if greater/equal
- 0x44: SETLE - Set if less/equal
- 0x45: SETGT - Set if greater than

#### System/Privileged Operations (0x50–0x5F)
- 0x50: HALT - Halt CPU
- 0x51: INT - Software interrupt

## Usage

1. **Access the tab**: Click on "Instruction Decoder" tab or press Ctrl+5
2. **Enter instruction**: Type a hex value (like `0x12345678`) or binary value in the input field
3. **Decode**: Press Enter or click "Decode" button
4. **View results**: 
   - Binary representation is shown at the top
   - Individual fields are displayed in the middle panel
   - Detailed breakdown appears in the text area below

## Example

Input: `0x00184400`
- Binary: `00000000000110000100010000000000`
- Opcode: 0x00 (ADD)
- RD: R3, RS1: R1, RS2: R2
- Operation: R3 = R1 + R2

## Keyboard Shortcuts
- **Ctrl+5**: Switch to Instruction Decoder tab
- **Enter**: Decode instruction (when input field is focused)
- **Clear**: Clear all fields and start over
