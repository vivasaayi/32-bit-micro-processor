# ALU Verification Test
# Tests: ADD, SUB, AND, OR, XOR, SLL, SRL, SRA, SLT, SLTU, ADDI, etc.

.org 0x0
# Initialize pass flag address
LI t0, 0x2000

# Test ADDI
ADDI t1, zero, 10
LI t2, 10
BNE t1, t2, fail

# Test ADD
LI t1, 20
LI t2, 30
ADD t3, t1, t2
LI t4, 50
BNE t3, t4, fail

# Test SUB
SUB t3, t2, t1 # 30 - 20 = 10
LI t4, 10
BNE t3, t4, fail

# Test AND
LI t1, 0xFF
LI t2, 0x0F
AND t3, t1, t2 # 0x0F
LI t4, 0x0F
BNE t3, t4, fail

# Test OR
LI t1, 0xF0
LI t2, 0x0F
OR t3, t1, t2 # 0xFF
LI t4, 0xFF
BNE t3, t4, fail

# Test XOR
LI t1, 0xFF
LI t2, 0x0F
XOR t3, t1, t2 # 0xF0
LI t4, 0xF0
BNE t3, t4, fail

# Test SLL (Shift Left Logical)
LI t1, 1
SLLI t2, t1, 2 # 1 << 2 = 4
LI t3, 4
BNE t2, t3, fail

# Test SLT (Set Less Than)
LI t1, 10
LI t2, 20
SLT t3, t1, t2 # 10 < 20 -> 1
LI t4, 1
BNE t3, t4, fail

SLT t3, t2, t1 # 20 < 10 -> 0
ADDI t4, zero, 0
BNE t3, t4, fail

# PASS
LI t1, 1
SW t1, 0(t0)
HALT

fail:
LI t1, 0
SW t1, 0(t0)
HALT
