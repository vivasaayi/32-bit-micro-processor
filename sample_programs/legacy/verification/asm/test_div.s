# RV32M Division and Remainder Test
# Tests: DIV, DIVU, REM, REMU operations

.org 0x0
# Initialize pass flag address
LI t0, 0x2000

# Test DIV: 20 / 3 = 6 (signed)
LI x6, 20
LI x7, 3
DIV x28, x6, x7 # x28 = 6
LI x29, 6
BNE x28, x29, fail

# Test DIVU: 20 / 3 = 6 (unsigned)
LI x6, 20
LI x7, 3
DIVU x28, x6, x7 # x28 = 6
LI x29, 6
BNE x28, x29, fail

# Test REM: 20 % 3 = 2 (signed)
LI x6, 20
LI x7, 3
REM x28, x6, x7 # x28 = 2
LI x29, 2
BNE x28, x29, fail

# Test REMU: 20 % 3 = 2 (unsigned)
LI x6, 20
LI x7, 3
REMU x28, x6, x7 # x28 = 2
LI x29, 2
BNE x28, x29, fail

# Test negative division: (-20) / 3 = -6 (signed)
LI x6, -20
LI x7, 3
DIV x28, x6, x7 # x28 = -6
LI x29, -6
BNE x28, x29, fail

# Test negative remainder: (-20) % 3 = -2 (signed, sign matches dividend)
LI x6, -20
LI x7, 3
REM x28, x6, x7 # x28 = -2
LI x29, -2
BNE x28, x29, fail

# Test division by zero: 20 / 0 = 0xFFFFFFFF (DIV)
LI x6, 20
LI x7, 0
DIV x28, x6, x7 # x28 = 0xFFFFFFFF
LI x29, 0xFFFFFFFF
BNE x28, x29, fail

# Test remainder by zero: 20 % 0 = 20 (REM)
LI x6, 20
LI x7, 0
REM x28, x6, x7 # x28 = 20
LI x29, 20
BNE x28, x29, fail

# Test signed overflow: INT_MIN / -1 = INT_MIN (DIV)
LI x6, 0x80000000 # INT_MIN
LI x7, 0xFFFFFFFF # -1
DIV x28, x6, x7 # x28 = 0x80000000
LI x29, 0x80000000
BNE x28, x29, fail

# Test signed overflow remainder: INT_MIN % -1 = 0 (REM)
LI x6, 0x80000000 # INT_MIN
LI x7, 0xFFFFFFFF # -1
REM x28, x6, x7 # x28 = 0
LI x29, 0
BNE x28, x29, fail

# PASS - All tests passed
LI x5, 1
SW x5, 0(t0)
HALT

fail:
LI x5, 0
SW x5, 0(t0)
HALT