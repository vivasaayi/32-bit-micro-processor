Here is a table of your CPU core opcodes and mnemonics, with each opcode value shown in binary, octal, hex, and decimal, along with a brief description:

| Mnemonic | Binary | Octal | Hex  | Dec | Description |
|----------|--------|-------|------|-----|-------------|
| ALU_ADD  | 000000 | 00    | 0x00 | 0   | a + b |
| ALU_SUB  | 000001 | 01    | 0x01 | 1   | a - b |
| ALU_AND  | 000010 | 02    | 0x02 | 2   | a & b |
| ALU_OR   | 000011 | 03    | 0x03 | 3   | a \| b |
| ALU_XOR  | 000100 | 04    | 0x04 | 4   | a ^ b |
| ALU_NOT  | 000101 | 05    | 0x05 | 5   | ~a |
| ALU_SHL  | 000110 | 06    | 0x06 | 6   | a << b |
| ALU_SHR  | 000111 | 07    | 0x07 | 7   | a >> b |
| ALU_MUL  | 001000 | 10    | 0x08 | 8   | a * b |
| ALU_DIV  | 001001 | 11    | 0x09 | 9   | a / b |
| ALU_MOD  | 001010 | 12    | 0x0A | 10  | a % b |
| ALU_CMP  | 001011 | 13    | 0x0B | 11  | compare a, b |
| ALU_SAR  | 001100 | 14    | 0x0C | 12  | a >>> b (arithmetic shift) |
| ALU_ADDI | 001101 | 15    | 0x0D | 13  | a + immediate |
| ALU_SUBI | 001110 | 16    | 0x0E | 14  | a - immediate |
| MEM_LOAD | 010000 | 20    | 0x10 | 16  | Load from memory |
| MEM_STORE| 010001 | 21    | 0x11 | 17  | Store to memory |
| MEM_LOADI| 010010 | 22    | 0x12 | 18  | Load immediate value into register (R[rd] = imm) |
| OP_JMP   | 100000 | 40    | 0x20 | 32  | Unconditional jump |
| OP_JZ    | 100001 | 41    | 0x21 | 33  | Jump if zero |
| OP_JNZ   | 100010 | 42    | 0x22 | 34  | Jump if not zero |
| OP_JC    | 100011 | 43    | 0x23 | 35  | Jump if carry |
| OP_JNC   | 100100 | 44    | 0x24 | 36  | Jump if not carry |
| OP_JLT   | 100101 | 45    | 0x25 | 37  | Jump if less than |
| OP_JGE   | 100110 | 46    | 0x26 | 38  | Jump if greater/equal |
| OP_JLE   | 100111 | 47    | 0x27 | 39  | Jump if less/equal |
| OP_CALL  | 101000 | 50    | 0x28 | 40  | Call subroutine |
| OP_RET   | 101001 | 51    | 0x29 | 41  | Return from subroutine |
| OP_PUSH  | 101010 | 52    | 0x2A | 42  | Push to stack |
| OP_POP   | 101011 | 53    | 0x2B | 43  | Pop from stack |
| OP_SETEQ | 110000 | 60    | 0x30 | 48  | Set if equal |
| OP_SETNE | 110001 | 61    | 0x31 | 49  | Set if not equal |
| OP_SETLT | 110010 | 62    | 0x32 | 50  | Set if less than |
| OP_SETGE | 110011 | 63    | 0x33 | 51  | Set if greater/equal |
| OP_SETLE | 110100 | 64    | 0x34 | 52  | Set if less/equal |
| OP_SETGT | 110101 | 65    | 0x35 | 53  | Set if greater than |
| OP_HALT  | 111110 | 76    | 0x3E | 62  | Halt CPU |
| OP_INT   | 111111 | 77    | 0x3F | 63  | Software interrupt |

**Notes:**
- All opcodes are 6-bit values (0x00–0x3F, 0–63 decimal)
- ADDI and SUBI are immediate versions of ADD and SUB
- Format: `ADDI rd, rs1, #immediate` → rd = rs1 + immediate
- Format: `SUBI rd, rs1, #immediate` → rd = rs1 - immediate
- Immediate values are 9-bit signed (-256 to +255)