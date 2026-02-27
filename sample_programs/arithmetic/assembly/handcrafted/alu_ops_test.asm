# alu_ops_test.asm - ALU operation test for custom CPU
# This program loads known values and exercises all ALU ops

LOADI   R1, 10 # R1 = 10
LOADI   R2, 3 # R2 = 3

ADD     R3, R1, R2 # R3 = 13
SUB     R4, R1, R2 # R4 = 7
AND     R5, R1, R2 # R5 = 2
OR      R6, R1, R2 # R6 = 11
XOR     R7, R1, R2 # R7 = 9
NOT     R8, R1 # R8 = ~10
SHL     R9, R1, R2 # R9 = 10 << 3 = 80
SHR     R10, R1, R2 # R10 = 10 >> 3 = 1
MUL     R11, R1, R2 # R11 = 30
DIV     R12, R1, R2 # R12 = 3
MOD     R13, R1, R2 # R13 = 1
CMP     R14, R1, R2 # R14 = (R1 - R2), flags set

HALT # End of test
