# Test ADDI (Add Immediate) Instruction
# This program tests adding immediate values to registers

main:
# Test basic ADDI operations
LOADI R1, #10 # R1 = 10
ADDI R2, R1, #5 # R2 = R1 + 5 = 15
ADDI R3, R2, #-3 # R3 = R2 + (-3) = 12
ADDI R4, R0, #42 # R4 = R0 + 42 = 42 (R0 is always 0)

# Test with larger immediate values
ADDI R5, R0, #255 # R5 = 255 (max positive 9-bit immediate)
ADDI R6, R0, #-256 # R6 = -256 (max negative 9-bit immediate)

# Chain ADDI operations
ADDI R7, R0, #1 # R7 = 1
ADDI R7, R7, #2 # R7 = 3
ADDI R7, R7, #4 # R7 = 7
ADDI R7, R7, #8 # R7 = 15

# Test flag effects (should set zero flag when result is 0)
LOADI R8, #5 # R8 = 5
ADDI R9, R8, #-5 # R9 = 0 (should set zero flag)

# Store results to memory for verification
STORE R2, 0x4000 # Store 15
STORE R3, 0x4004 # Store 12
STORE R4, 0x4008 # Store 42
STORE R7, 0x400C # Store 15
STORE R9, 0x4010 # Store 0

HALT
