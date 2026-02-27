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
#addi R8, R2, 5

# SUBI: R9 = R3 - 7
#addi R9, R3, -7

# CMP: Compare R2 and R3 (result in flags)
CMP R2, R3

# Store results to memory for verification
sw R1, 0(100)
sw R4, 0(104)
sw R5, 0(108)
sw R6, 0(112)
sw R7, 0(116)
sw R8, 0(120)
sw R9, 0(124)

# End of test
HALT
