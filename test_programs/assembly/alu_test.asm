# ALU Operation Test Program
# This program tests all ALU operations for the 32-bit CPU

# ADD: R1 = R2 + R3
LOADI R2, 10
LOADI R3, 20
ADD R1, R2, R3

# SUB: R4 = R1 - R2
SUB R4, R1, R2

# AND: R5 = R2 & R3
AND R5, R2, R3

# OR: R6 = R2 | R3
OR R6, R2, R3

# XOR: R7 = R2 ^ R3
XOR R7, R2, R3

# ADDI: R8 = R2 + 5
ADDI R8, R2, 5

# SUBI: R9 = R3 - 7
SUBI R9, R3, 7

# CMP: Compare R2 and R3 (result in flags)
CMP R2, R3

# Store results to memory for verification
STORE R1, 100
STORE R4, 104
STORE R5, 108
STORE R6, 112
STORE R7, 116
STORE R8, 120
STORE R9, 124

# End of test
HALT
