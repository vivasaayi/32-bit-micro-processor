# 32-Bit Microprocessor Instruction Set Architecture

## Register Set

### General Purpose Registers (32-bit)
- **R0-R31**: General purpose registers (32-bit each)
- **R0**: Hardwired to zero (RISC convention)
- **R1-R30**: General purpose
- **R31**: Often used as link register for function calls

### Calling Convention (Recommended)
- **R1-R8**: Function arguments and return values
- **R9-R15**: Temporary registers (caller-saved)
- **R16-R23**: Saved registers (callee-saved)
- **R24-R28**: More temporaries
- **R29**: Frame pointer
- **R30**: Stack pointer
- **R31**: Return address (link register)

### Special Purpose Registers
- **PC**: Program Counter (32-bit) - Points to next instruction
- **FLAGS**: Status register (8-bit)
  - Bit 0: Carry (C)
  - Bit 1: Zero (Z)
  - Bit 2: Negative (N)
  - Bit 3: Overflow (V)
  - Bit 4-7: Reserved

## Instruction Formats

All instructions are 32 bits wide with two main formats:

### Format 1: Standard Register Format
```
[31:27] OPCODE (5 bits) | [26:24] FUNC (3 bits) | [23:19] RD (5 bits) | [18:14] RS1 (5 bits) | [13:9] RS2 (5 bits) | [8:0] IMM9 (9 bits)
```

### Format 2: Large Immediate Format  
```
[31:27] OPCODE (5 bits) | [26:24] RESERVED (3 bits) | [23:19] RD (5 bits) | [18:0] IMM19 (19 bits)
```

## Memory Architecture

- **Address Space**: 4GB (32-bit addressing)
- **Data Width**: 32-bit
- **Word Alignment**: All addresses must be 4-byte aligned
- **Internal Memory**: 0x00000000 - 0x000FFFFF (1MB)
- **External Memory**: 0x00100000 - 0xFFFFFFFF (4GB - 1MB)

## Instruction Set

### Data Movement (0x01-0x03)

| Mnemonic | Opcode | Format | Description | Example |
|----------|--------|--------|-------------|---------|
| LOADI    | 0x01   | Large Imm | Load 19-bit immediate into register | `LOADI R1, #65535` |
| LOAD     | 0x02   | Standard | Load from memory address | `LOAD R1, #0x1000` |
| STORE    | 0x03   | Standard/Large | Store register to memory | `STORE R1, #0x1000` |

**LOAD/STORE Addressing Modes:**
- Direct: `LOAD R1, #0x1000` (address in immediate, 19-bit range)
- Register+Offset: `LOAD R1, R2, #4` (R2 + offset, 9-bit offset)
- Register: `LOAD R1, [R2]` (address in R2)

### Arithmetic Instructions (0x04-0x07)

| Mnemonic | Opcode | Format | Description | Example |
|----------|--------|--------|-------------|---------|
| ADD      | 0x04   | Standard | Add two registers | `ADD R3, R1, R2` |
| ADDI     | 0x05   | Standard | Add register and 9-bit immediate | `ADDI R1, R1, #10` |
| SUB      | 0x06   | Standard | Subtract two registers | `SUB R3, R1, R2` |
| SUBI     | 0x07   | Standard | Subtract 9-bit immediate from register | `SUBI R1, R1, #5` |

### Logical Instructions (0x08-0x0A)

| Mnemonic | Opcode | Format | Description | Example |
|----------|--------|--------|-------------|---------|
| AND      | 0x08   | Standard | Bitwise AND | `AND R3, R1, R2` |
| OR       | 0x09   | Standard | Bitwise OR | `OR R3, R1, R2` |
| XOR      | 0x0A   | Standard | Bitwise XOR | `XOR R3, R1, R2` |

### Shift Instructions (0x0B-0x0C)

| Mnemonic | Opcode | Format | Description | Example |
|----------|--------|--------|-------------|---------|
| SHL      | 0x0B   | Standard | Shift left logical | `SHL R1, R2, #3` |
| SHR      | 0x0C   | Standard | Shift right logical | `SHR R1, R2, #3` |

### Compare and Control (0x0D-0x15)

| Mnemonic | Opcode | Format | Description | Example |
|----------|--------|--------|-------------|---------|
| CMP      | 0x0D   | Standard | Compare two registers (sets flags) | `CMP R1, R2` |
| JMP      | 0x0E   | Standard | Unconditional jump | `JMP LABEL` |
| JZ       | 0x0F   | Standard | Jump if zero flag set | `JZ LABEL` |
| JNZ      | 0x10   | Standard | Jump if zero flag clear | `JNZ LABEL` |
| JC       | 0x11   | Standard | Jump if carry flag set | `JC LABEL` |
| JNC      | 0x12   | Standard | Jump if carry flag clear | `JNC LABEL` |
| JLT      | 0x13   | Standard | Jump if less than (N flag set) | `JLT LABEL` |
| JGE      | 0x14   | Standard | Jump if greater/equal (N flag clear) | `JGE LABEL` |
| JLE      | 0x15   | Standard | Jump if less/equal (Z or N flag set) | `JLE LABEL` |

### System Instructions (0x1F)

| Mnemonic | Opcode | Format | Description | Example |
|----------|--------|--------|-------------|---------|
| HALT     | 0x1F   | Standard | Halt processor execution | `HALT` |

## Branch Addressing

Branches use PC-relative addressing with 9-bit signed offsets:
- Offset is in **words** (not bytes)
- Range: -256 to +255 words (-1KB to +1KB)
- Calculation: `PC = PC + (sign_extend(offset) << 2)`

## Flag Updates

Flags are updated by:
- **Arithmetic operations** (ADD, ADDI, SUB, SUBI)
- **Compare operations** (CMP)
- **Logical operations** (AND, OR, XOR)

Flag meanings:
- **C (Carry)**: Set on unsigned overflow
- **Z (Zero)**: Set when result is zero
- **N (Negative)**: Set when result is negative (bit 31 = 1)
- **V (Overflow)**: Set on signed overflow

## Assembler Syntax

### Registers
- `R0, R1, R2, ..., R31`
- R0 is always zero

### Immediates
- Decimal: `#42`, `#-10`
- Hexadecimal: `#0x1000`, `#0xFF`

### Labels
- `LOOP:`, `END:`
- Case sensitive

### Comments
- `;` for line comments
- `; This is a comment`

## Example Programs

### Simple Addition
```assembly
LOADI R1, #100      ; Load 100 into R1
LOADI R2, #200      ; Load 200 into R2  
ADD R3, R1, R2      ; R3 = R1 + R2 = 300
STORE R3, #0x1000   ; Store result to memory
HALT                ; Stop execution
```

### Loop Example
```assembly
LOADI R1, #10       ; Counter = 10
LOADI R2, #0        ; Sum = 0
LOOP:
    ADD R2, R2, R1  ; Sum += Counter
    SUBI R1, R1, #1 ; Counter--
    JNZ LOOP        ; Jump if Counter != 0
STORE R2, #0x1004   ; Store sum
HALT
```

## Memory Map

| Address Range | Description |
|---------------|-------------|
| 0x00000000 - 0x000003FF | Boot ROM/Reset vector |
| 0x00000400 - 0x000FFFFF | Internal RAM (1MB) |
| 0x00100000 - 0x7FFFFFFF | External RAM |
| 0x80000000 - 0xFFFFFFFF | Memory-mapped I/O |

## Performance Notes

- **Pipeline**: 5-stage (FETCH → DECODE → EXECUTE → MEMORY → WRITEBACK)
- **Hazards**: No hazard detection implemented (software must handle)
- **Branch Penalty**: 2 cycles for taken branches
- **Memory Latency**: 1 cycle for internal memory, variable for external
