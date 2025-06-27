# 8-Bit Microprocessor Instruction Set Architecture

## Register Set

### General Purpose Registers (8-bit)
- **R0-R7**: General purpose registers
- **R0**: Often used as accumulator
- **R1-R6**: General purpose
- **R7**: Often used as temporary register

### Special Purpose Registers
- **SP**: Stack Pointer (16-bit) - Points to top of stack
- **PC**: Program Counter (16-bit) - Points to next instruction
- **FLAGS**: Status register (8-bit)
  - Bit 0: Carry (C)
  - Bit 1: Zero (Z)
  - Bit 2: Negative (N)
  - Bit 3: Overflow (V)
  - Bit 4: Interrupt Enable (I)
  - Bit 5: User/Kernel Mode (U)
  - Bit 6-7: Reserved

## Instruction Formats

### Format 1: Register-Immediate (8-bit instruction)
```
[7:4] OPCODE | [3:1] REG | [0] IMM_FLAG
```

### Format 2: Register-Register (8-bit instruction)
```
[7:4] OPCODE | [3:2] REG1 | [1:0] REG2
```

### Format 3: Control Flow (8-bit instruction + optional 16-bit address)
```
[7:0] OPCODE
[15:0] ADDRESS (optional, for jumps/calls)
```

## Instruction Set

### Arithmetic Instructions (0x0X)
| Mnemonic | Opcode | Format | Description |
|----------|--------|--------|-------------|
| ADD      | 0x00   | Reg-Reg| R1 = R1 + R2 |
| SUB      | 0x01   | Reg-Reg| R1 = R1 - R2 |
| ADC      | 0x02   | Reg-Reg| R1 = R1 + R2 + Carry |
| SBC      | 0x03   | Reg-Reg| R1 = R1 - R2 - Carry |
| ADDI     | 0x04   | Reg-Imm| R1 = R1 + Immediate |
| SUBI     | 0x05   | Reg-Imm| R1 = R1 - Immediate |

### Logic Instructions (0x1X)
| Mnemonic | Opcode | Format | Description |
|----------|--------|--------|-------------|
| AND      | 0x10   | Reg-Reg| R1 = R1 & R2 |
| OR       | 0x11   | Reg-Reg| R1 = R1 \| R2 |
| XOR      | 0x12   | Reg-Reg| R1 = R1 ^ R2 |
| NOT      | 0x13   | Reg    | R1 = ~R1 |
| ANDI     | 0x14   | Reg-Imm| R1 = R1 & Immediate |
| ORI      | 0x15   | Reg-Imm| R1 = R1 \| Immediate |

### Shift Instructions (0x2X)
| Mnemonic | Opcode | Format | Description |
|----------|--------|--------|-------------|
| SHL      | 0x20   | Reg    | R1 = R1 << 1 |
| SHR      | 0x21   | Reg    | R1 = R1 >> 1 |
| ROL      | 0x22   | Reg    | Rotate left |
| ROR      | 0x23   | Reg    | Rotate right |

### Memory Instructions (0x3X)
| Mnemonic | Opcode | Format | Description |
|----------|--------|--------|-------------|
| LOAD     | 0x30   | Reg-Addr| R1 = Memory[Address] |
| STORE    | 0x31   | Reg-Addr| Memory[Address] = R1 |
| LOADI    | 0x32   | Reg-Imm| R1 = Immediate |
| LOADR    | 0x33   | Reg-Reg| R1 = Memory[R2] |
| STORER   | 0x34   | Reg-Reg| Memory[R2] = R1 |

### Branch Instructions (0x4X)
| Mnemonic | Opcode | Format | Description |
|----------|--------|--------|-------------|
| JMP      | 0x40   | Addr   | PC = Address |
| JEQ      | 0x41   | Addr   | Jump if Zero flag set |
| JNE      | 0x42   | Addr   | Jump if Zero flag clear |
| JLT      | 0x43   | Addr   | Jump if Negative flag set |
| JGE      | 0x44   | Addr   | Jump if Negative flag clear |
| JCS      | 0x45   | Addr   | Jump if Carry flag set |
| JCC      | 0x46   | Addr   | Jump if Carry flag clear |

### Subroutine Instructions (0x5X)
| Mnemonic | Opcode | Format | Description |
|----------|--------|--------|-------------|
| CALL     | 0x50   | Addr   | Push PC, PC = Address |
| RET      | 0x51   | -      | Pop PC |
| PUSH     | 0x52   | Reg    | Push register to stack |
| POP      | 0x53   | Reg    | Pop from stack to register |

### System Instructions (0x6X)
| Mnemonic | Opcode | Format | Description |
|----------|--------|--------|-------------|
| SYSCALL  | 0x60   | Imm    | System call |
| IRET     | 0x61   | -      | Return from interrupt |
| EI       | 0x62   | -      | Enable interrupts |
| DI       | 0x63   | -      | Disable interrupts |
| HALT     | 0x64   | -      | Halt processor |
| NOP      | 0x65   | -      | No operation |

### I/O Instructions (0x7X)
| Mnemonic | Opcode | Format | Description |
|----------|--------|--------|-------------|
| IN       | 0x70   | Reg-Port| R1 = Input from port |
| OUT      | 0x71   | Reg-Port| Output R1 to port |

### Compare Instructions (0x8X)
| Mnemonic | Opcode | Format | Description |
|----------|--------|--------|-------------|
| CMP      | 0x80   | Reg-Reg| Compare R1 with R2 (sets flags) |
| CMPI     | 0x81   | Reg-Imm| Compare R1 with immediate |

## System Calls

The processor supports system calls through the SYSCALL instruction. System call numbers:

| Number | Name      | Description |
|--------|-----------|-------------|
| 0x00   | exit      | Terminate process |
| 0x01   | read      | Read from file descriptor |
| 0x02   | write     | Write to file descriptor |
| 0x03   | open      | Open file |
| 0x04   | close     | Close file |
| 0x05   | fork      | Create new process |
| 0x06   | exec      | Execute new program |
| 0x07   | wait      | Wait for child process |
| 0x08   | getpid    | Get process ID |
| 0x09   | sleep     | Sleep for specified time |
| 0x0A   | malloc    | Allocate memory |
| 0x0B   | free      | Free memory |

## Memory-Mapped I/O

| Address Range | Device |
|---------------|--------|
| 0xF000-0xF00F | UART |
| 0xF010-0xF01F | Timer |
| 0xF020-0xF02F | Interrupt Controller |
| 0xF030-0xF03F | GPIO |
| 0xF040-0xF04F | MMU Control |

## Assembly Language Syntax

### Instructions
```assembly
; Arithmetic
ADD R1, R2        ; R1 = R1 + R2
ADDI R1, #5       ; R1 = R1 + 5

; Memory
LOAD R1, 0x1000   ; R1 = Memory[0x1000]
STORE R1, 0x1000  ; Memory[0x1000] = R1
LOADI R1, #10     ; R1 = 10

; Control Flow
JMP 0x2000        ; Jump to address 0x2000
JEQ loop          ; Jump to 'loop' if zero flag set

; System
SYSCALL #1        ; System call #1 (read)
```

### Labels and Comments
```assembly
loop:             ; Label
    ADD R1, R2    ; Add R2 to R1
    SUBI R1, #1   ; Subtract 1 from R1
    JNE loop      ; Jump back if not zero
```
