# Add values from all general-purpose registers (R1 to R31) and store the result in R30

main:
# Initialize registers with different values (R1 to R31)
addi R1, zero, 1
addi R2, zero, 2
addi R3, zero, 3
addi R4, zero, 4
addi R5, zero, 5
addi R6, zero, 6
addi R7, zero, 7
addi R8, zero, 8
addi R9, zero, 9
addi R10, zero, 10
addi R11, zero, 11
addi R12, zero, 12
addi R13, zero, 13
addi R14, zero, 14
addi R15, zero, 15
addi R16, zero, 16
addi R17, zero, 17
addi R18, zero, 18
addi R19, zero, 19
addi R20, zero, 20
addi R21, zero, 21
addi R22, zero, 22
addi R23, zero, 23
addi R24, zero, 24
addi R25, zero, 25
addi R26, zero, 26
addi R27, zero, 27
addi R28, zero, 28
addi R29, zero, 29
addi R30, zero, 30
addi R31, zero, 31

# Accumulate sum in R30 (skip R0)
# addi R30, zero, 0
ADD R30, R30, R1
ADD R30, R30, R2
ADD R30, R30, R3
ADD R30, R30, R4
ADD R30, R30, R5
ADD R30, R30, R6
ADD R30, R30, R7
ADD R30, R30, R8
ADD R30, R30, R9
ADD R30, R30, R10
ADD R30, R30, R11
ADD R30, R30, R12
ADD R30, R30, R13
ADD R30, R30, R14
ADD R30, R30, R15
ADD R30, R30, R16
ADD R30, R30, R17
ADD R30, R30, R18
ADD R30, R30, R19
ADD R30, R30, R20
ADD R30, R30, R21
ADD R30, R30, R22
ADD R30, R30, R23
ADD R30, R30, R24
ADD R30, R30, R25
ADD R30, R30, R26
ADD R30, R30, R27
ADD R30, R30, R28
ADD R30, R30, R29
#ADD R30, R30, R30
ADD R30, R30, R31

# Store result for verification
sw R30, 0(0x8000) # Store sum of 1..31 = 496
HALT
