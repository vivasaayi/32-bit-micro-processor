# Test SUBI (Subtract Immediate) Instruction
# This program tests subtracting immediate values from registers

main:
# Test basic SUBI operations
addi R1, zero, 20 # R1 = 20
addi R2, R1, -5 # R2 = R1 - 5 = 15
addi R3, R2, -10 # R3 = R2 - 10 = 5
addi R4, R1, -0 # R4 = R1 - 0 = 20 (no change)

# Test with negative immediate (double negative = addition)
SUBI R5, R1, #-3 # R5 = R1 - (-3) = 20 + 3 = 23

# Test edge cases
addi R6, zero, 10 # R6 = 10
addi R7, R6, -10 # R7 = 0 (should set zero flag)
addi R8, R6, -15 # R8 = -5 (negative result, should set negative flag)

# Test with maximum immediate values
addi R9, zero, 300 # R9 = 300
addi R10, R9, -255 # R10 = 300 - 255 = 45
SUBI R11, R9, #-256 # R11 = 300 - (-256) = 556

# Chain SUBI operations
addi R12, zero, 100 # R12 = 100
addi R12, R12, -10 # R12 = 90
addi R12, R12, -20 # R12 = 70
addi R12, R12, -30 # R12 = 40

# Mixed ADDI and SUBI operations
addi R13, zero, 50 # R13 = 50
addi R13, R13, 25 # R13 = 75
addi R13, R13, -15 # R13 = 60
addi R13, R13, 5 # R13 = 65
addi R13, R13, -20 # R13 = 45

# Store results to memory for verification
sw R2, 0(0x5000) # Store 15
sw R3, 0(0x5004) # Store 5
sw R5, 0(0x5008) # Store 23
sw R7, 0(0x500C) # Store 0
sw R8, 0(0x5010) # Store -5
sw R12, 0(0x5014) # Store 40
sw R13, 0(0x5018) # Store 45

HALT
