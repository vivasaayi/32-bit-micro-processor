# Test all 32 registers: initialize to 0, then add 2 to each (except R0) in a loop, 5 times.
# R1-R30 are the data registers. R31 is the loop counter.
# R0 will always remain 0.
# After 5 loops, R1-R30 should each contain the value 10.

.org 0x8000

main:
# Initialize data registers R1-R30 to 0.
# R0 is hardwired to 0, so we can use it for initialization.
ADD R1, R0, R0
ADD R2, R0, R0
ADD R3, R0, R0
ADD R4, R0, R0
ADD R5, R0, R0
ADD R6, R0, R0
ADD R7, R0, R0
ADD R8, R0, R0
ADD R9, R0, R0
ADD R10, R0, R0
ADD R11, R0, R0
ADD R12, R0, R0
ADD R13, R0, R0
ADD R14, R0, R0
ADD R15, R0, R0
ADD R16, R0, R0
ADD R17, R0, R0
ADD R18, R0, R0
ADD R19, R0, R0
ADD R20, R0, R0
ADD R21, R0, R0
ADD R22, R0, R0
ADD R23, R0, R0
ADD R24, R0, R0
ADD R25, R0, R0
ADD R26, R0, R0
ADD R27, R0, R0
ADD R28, R0, R0
ADD R29, R0, R0
ADD R30, R0, R0

# Set up loop counter in R31
addi R31, zero, 5

loop_start:
# Add 2 to each register R1-R30
addi R1, R1, 2
addi R2, R2, 2
addi R3, R3, 2
addi R4, R4, 2
addi R5, R5, 2
addi R6, R6, 2
addi R7, R7, 2
addi R8, R8, 2
addi R9, R9, 2
addi R10, R10, 2
addi R11, R11, 2
addi R12, R12, 2
addi R13, R13, 2
addi R14, R14, 2
addi R15, R15, 2
addi R16, R16, 2
addi R17, R17, 2
addi R18, R18, 2
addi R19, R19, 2
addi R20, R20, 2
addi R21, R21, 2
addi R22, R22, 2
addi R23, R23, 2
addi R24, R24, 2
addi R25, R25, 2
addi R26, R26, 2
addi R27, R27, 2
addi R28, R28, 2
addi R29, R29, 2
addi R30, R30, 2

# Decrement loop counter and branch if not zero (use CMP/JZ/JMP style)
addi R31, R31, -1
CMP R31, R0
JZ end_loop
JMP loop_start

end_loop:
# Store results for verification
# R1-R30 should all be 10
sw R1, 0(0x8001)
sw R2, 0(0x8002)
sw R3, 0(0x8003)
sw R4, 0(0x8004)
sw R5, 0(0x8005)
sw R6, 0(0x8006)
sw R7, 0(0x8007)
sw R8, 0(0x8008)
sw R9, 0(0x8009)
sw R10, 0(0x800A)
sw R11, 0(0x800B)
sw R12, 0(0x800C)
sw R13, 0(0x800D)
sw R14, 0(0x800E)
sw R15, 0(0x800F)
sw R16, 0(0x8010)
sw R17, 0(0x8011)
sw R18, 0(0x8012)
sw R19, 0(0x8013)
sw R20, 0(0x8014)
sw R21, 0(0x8015)
sw R22, 0(0x8016)
sw R23, 0(0x8017)
sw R24, 0(0x8018)
sw R25, 0(0x8019)
sw R26, 0(0x801A)
sw R27, 0(0x801B)
sw R28, 0(0x801C)
sw R29, 0(0x801D)
sw R30, 0(0x801E)
sw R31, 0(0x801F) # Store final counter value (should be 0)

HALT
