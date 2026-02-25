# Arithmetic R-Type
ADD x1, x2, x3
SUB x4, x5, x6
SLL x7, x8, x9
SLT x10, x11, x12
SLTU x13, x14, x15
XOR x16, x17, x18
SRL x19, x20, x21
SRA x22, x23, x24
OR x25, x26, x27
AND x28, x29, x30

# Arithmetic I-Type
ADDI x1, x2, 123
SLTI x3, x4, -1
SLTIU x5, x6, 0xFF
XORI x7, x8, 0xF
ORI x9, x10, 0xA
ANDI x11, x12, 0x3
SLLI x13, x14, 4
SRLI x15, x16, 5
SRAI x17, x18, 6

# Loads
LB x1, 0(x2)
LH x3, 4(x4)
LW x5, -4(x6)
LBU x7, 8(x8)
LHU x9, 12(x10)

# Stores
SB x11, 0(x12)
SH x13, 2(x14)
SW x15, 4(x16)

# Branches
BEQ x1, x2, label_fwd
BNE x3, x4, label_fwd
BLT x5, x6, label_fwd
BGE x7, x8, label_fwd
BLTU x9, x10, label_fwd
BGEU x11, x12, label_fwd
label_fwd:
ADDI x0, x0, 0  # Replaced NOP

# Jumps
JAL x1, label_jump
ADDI x0, x0, 0  # Replaced NOP
label_jump:
JALR x2, 0(x3)

# System
ECALL
EBREAK
CSRRW x1, 0x300, x2
CSRRS x3, 0x304, x4
CSRRC x5, 0x341, x6
