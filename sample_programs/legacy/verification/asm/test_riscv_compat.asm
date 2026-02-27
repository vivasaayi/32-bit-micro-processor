# Comprehensive RISC-V compatibility test
.org 0x0

# Test RV32I base instructions
LI x1, 100 # Test immediate loading
LI x2, 200
ADD x3, x1, x2 # x3 = 300
SUB x4, x2, x1 # x4 = 100
AND x5, x3, x4 # x5 = 100 & 100 = 100
OR x6, x3, x4 # x6 = 300 | 100 = 300
XOR x7, x3, x4 # x7 = 300 ^ 100 = 200
SLL x8, x1, x4 # x8 = 100 << 100 (shift by lower 5 bits = 4) = 1600
SRL x9, x8, x4 # x9 = 1600 >> 4 = 100
SRA x10, x8, x4 # x10 = 1600 >> 4 = 100 (arithmetic)

# Test immediate operations
ADDI x11, x1, 50 # x11 = 100 + 50 = 150
ANDI x12, x11, 15 # x12 = 150 & 15 = 6
ORI x13, x12, 240 # x13 = 6 | 240 = 246
XORI x14, x13, 255 # x14 = 246 ^ 255 = 9
SLLI x15, x1, 2 # x15 = 100 << 2 = 400
SRLI x16, x15, 2 # x16 = 400 >> 2 = 100
SRAI x17, x15, 2 # x17 = 400 >> 2 = 100

# Test comparisons
SLT x18, x1, x2 # x18 = (100 < 200) = 1
SLTU x19, x2, x1 # x19 = (200 < 100) unsigned = 0
SLTI x20, x1, 150 # x20 = (100 < 150) = 1
SLTIU x21, x2, 150 # x21 = (200 < 150) unsigned = 0

# Test memory operations
LI x22, 0x2000 # Base address
SW x1, 0(x22) # Store 100 at 0x2000
SW x2, 4(x22) # Store 200 at 0x2004
LW x23, 0(x22) # Load 100
LW x24, 4(x22) # Load 200

# Test branches (will be taken)
BEQ x23, x1, branch_taken # Should branch
LI x25, 999 # Should be skipped
branch_taken:
LI x25, 42 # Should execute

# Test RV32M multiplication
MUL x26, x1, x2 # x26 = 100 * 200 = 20000
MULH x27, x1, x2 # Upper 32 bits of 20000 = 0
LI x28, -100
MULHSU x29, x28, x2 # Signed * unsigned: upper bits of -100 * 200

# Test RV32M division
LI x30, 200
LI x31, 100
DIV x1, x30, x31 # 200 / 100 = 2
DIVU x2, x30, x31 # 200 / 100 = 2 (unsigned)
REM x3, x30, x31 # 200 % 100 = 0
REMU x4, x30, x31 # 200 % 100 = 0 (unsigned)

# Store results for verification
SW x1, 0(x22) # Store 2
SW x2, 4(x22) # Store 2
SW x3, 8(x22) # Store 0
SW x4, 12(x22) # Store 0
HALT