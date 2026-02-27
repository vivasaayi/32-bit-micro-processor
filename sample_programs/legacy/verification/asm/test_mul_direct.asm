# Simple RV32M Multiplication Test - Direct check
# Tests basic MUL and MULH operations without branches

.org 0x0
# Initialize pass flag address
LI t0, 0x2000

# Test MUL: 10 * 20 = 200
LI x6, 10
LI x7, 20
MUL x28, x6, x7 # x28 = 200
SW x28, 0(t0) # Store result as status

# Test MULH: (-1) * (-1) = 1, upper bits = 0
LI x6, 0xFFFFFFFF
LI x7, 0xFFFFFFFF
MULH x29, x6, x7 # x29 = 0
SW x29, 4(t0) # Store upper result

# If both are correct, status will be 200 at 0x2000 and 0 at 0x2004
HALT