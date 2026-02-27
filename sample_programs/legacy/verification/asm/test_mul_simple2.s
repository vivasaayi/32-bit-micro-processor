# Simple RV32M Multiplication Test with explicit registers
# Tests basic MUL and MULH operations

.org 0x0
# Initialize pass flag address
LI t0, 0x2000

# Test MUL with small numbers: 10 * 20 = 200
LI x6, 10 # x6 = 10
LI x7, 20 # x7 = 20
MUL x28, x6, x7 # x28 = 200
LI x29, 200 # x29 = 200
BNE x28, x29, fail

# Test MULH with -1 * -1 = 1, upper bits = 0
LI x6, 0xFFFFFFFF # x6 = -1
LI x7, 0xFFFFFFFF # x7 = -1
MULH x28, x6, x7 # x28 = 0 (upper 32 bits of 1)
LI x29, 0 # x29 = 0
BNE x28, x29, fail

# PASS - All tests passed
LI x5, 1
SW x5, 0(t0)
HALT

fail:
LI x5, 0
SW x5, 0(t0)
HALT