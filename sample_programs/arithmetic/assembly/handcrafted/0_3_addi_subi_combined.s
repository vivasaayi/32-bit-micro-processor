# Combined ADDI/SUBI Test Program
# This program tests both ADDI and SUBI in various combinations

main:
# Initialize base values
addi R1, zero, 100 # R1 = 100 (base value)
addi R2, zero, 0 # R2 = 0 (accumulator)

# Test arithmetic sequence with immediate operations
addi R2, R2, 10 # R2 = 10
addi R2, R2, -3 # R2 = 7
addi R2, R2, 8 # R2 = 15
addi R2, R2, -2 # R2 = 13

# Test with base register
addi R3, R1, 50 # R3 = 150 (100 + 50)
addi R4, R1, -25 # R4 = 75 (100 - 25)

# Test boundary conditions
addi R5, R0, 255 # R5 = 255 (max positive immediate)
addi R6, R5, -255 # R6 = 0 (should set zero flag)
addi R7, R0, -256 # R7 = -256 (max negative immediate)
SUBI R8, R0, #-256 # R8 = 256 (subtract negative = add positive)

# Comparison with regular ADD/SUB
addi R9, zero, 5 # R9 = 5 (for comparison)
ADD R10, R1, R9 # R10 = 105 (100 + 5 using ADD)
addi R11, R1, 5 # R11 = 105 (100 + 5 using ADDI)

SUB R12, R1, R9 # R12 = 95 (100 - 5 using SUB)
addi R13, R1, -5 # R13 = 95 (100 - 5 using SUBI)

# Test flag setting with immediate operations
addi R14, R0, 127 # R14 = 127
addi R14, R14, 127 # R14 = 254 (test positive overflow)

addi R15, R0, -1 # R15 = -1 (test negative flag)

# Store verification values
sw R2, 0(0x6000) # Store 13
sw R3, 0(0x6004) # Store 150
sw R4, 0(0x6008) # Store 75
sw R6, 0(0x600C) # Store 0
sw R8, 0(0x6010) # Store 256
sw R10, 0(0x6014) # Store 105 (ADD result)
sw R11, 0(0x6018) # Store 105 (ADDI result - should match)
sw R12, 0(0x601C) # Store 95 (SUB result)
sw R13, 0(0x6020) # Store 95 (SUBI result - should match)

# Final test: increment/decrement pattern
addi R16, zero, 0 # R16 = 0
addi R16, R16, 1 # R16 = 1
addi R16, R16, 1 # R16 = 2
addi R16, R16, 1 # R16 = 3
addi R16, R16, -1 # R16 = 2
addi R16, R16, -1 # R16 = 1
sw R16, 0(0x6024) # Store 1

HALT
