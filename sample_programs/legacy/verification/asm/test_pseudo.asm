# Pseudo-Instruction Verification
# Tests: LI, LA, MV, NOT, NEG, Large constants

.org 0x0
LI s0, 0x2000

# Test MV
LI t1, 123
MV t2, t1
BNE t1, t2, fail

# Test NOT
LI t1, 0
NOT t2, t1 # Should be -1 (0xFFFFFFFF)
LI t3, -1
BNE t2, t3, fail

# Test NEG
LI t1, 10
NEG t2, t1
LI t3, -10
BNE t2, t3, fail

# Test LI with large value (requires LUI + ADDI)
# 0x12345678 => LUI 0x12345, ADDI 0x678
LI t1, 0x12345678

# Verification tricky without hardcoding
# Check upper bits
SRLI t2, t1, 20 # top 12 bits? No LUI is U-type.
# Just store and check in sim? No, we need self-check.
# Check against split construction
LUI t3, 0x12345
ADDI t3, t3, 0x678
BNE t1, t3, fail

# PASS
LI t1, 1
SW t1, 0(s0)
HALT

fail:
LI t1, 0
SW t1, 0(s0)
HALT
