# Opcode Encoder Tab

## Overview
The Opcode Encoder tab allows you to create 32-bit instructions by selecting an opcode and specifying operands. It's the reverse of the Instruction Decoder - instead of decoding existing instructions, you build them from scratch.

## Features

### Instruction Building
1. **Select Opcode**: Choose from a dropdown of all supported opcodes
2. **Enter Operands**: Specify register numbers and immediate values
3. **Auto-format**: The tab shows the correct format for each instruction type
4. **Generate**: Get hex, binary, and assembly representations

### Input Fields
- **Opcode**: Dropdown menu with all supported mnemonics (ADD, SUB, LOAD, etc.)
- **RD**: Destination register (0-31)
- **RS1**: Source register 1 (0-31)  
- **RS2**: Source register 2 (0-31)
- **IMM**: Immediate value (decimal or hex with 0x prefix)

### Output Formats
- **Hex**: 32-bit hexadecimal representation (e.g., 0x00184400)
- **Binary**: 32-bit binary with field annotations
- **Assembly**: Human-readable assembly format
- **Verilog**: Ready-to-use testbench code

## Supported Instruction Types

### ALU Operations (Register-Register-Register format)
- **Format**: `OPCODE RD, RS1, RS2`
- **Examples**: 
  - `ADD R3, R1, R2` → R3 = R1 + R2
  - `SUB R4, R1, R2` → R4 = R1 - R2
  - `AND R5, R1, R2` → R5 = R1 & R2

### Memory Operations (Register-Immediate format)
- **LOAD Format**: `LOAD RD, [IMM]` → RD = MEM[IMM]
- **STORE Format**: `STORE RD, [IMM]` → MEM[IMM] = RD

### Control Operations
- **Branch Format**: `JZ [IMM]` → Jump to IMM if zero flag set
- **Call Format**: `CALL [IMM]` → Call subroutine at IMM
- **Stack Format**: `PUSH RD` → Push RD to stack

### Set Operations (Register-Register-Register format)
- **Format**: `SETEQ RD, RS1, RS2` → RD = (RS1 == RS2) ? 1 : 0

## Usage Example

To encode `ADD R3, R1, R2`:
1. Select "ADD" from opcode dropdown
2. Enter RD: 3, RS1: 1, RS2: 2
3. Click "Encode"
4. Get result: `0x00184400`

## Output Details

The encoder provides:
- **Hex Output**: `0x00184400`
- **Binary**: `00000000000110000100010000000000` with field markers
- **Assembly**: `ADD R3, R1, R2`
- **Verilog**: `mem[addr] = encode_rrr(6'h00, 5'd3, 5'd1, 5'd2);`

## Format Information

The tab automatically shows the correct format for each opcode:
- **ALU**: `ADD RD, RS1, RS2`
- **Memory**: `LOAD RD, [IMM]`
- **Branch**: `JZ [IMM]`
- **System**: `HALT`

## Keyboard Shortcuts
- **Ctrl+6**: Switch to Opcode Encoder tab
- **Enter**: Encode instruction (from any input field)
- **Clear**: Reset all fields

## Integration with Other Tabs
- Copy hex output to Instruction Decoder tab for verification
- Use generated Verilog code in testbench templates
- Export assembly format for documentation
