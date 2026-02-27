# Combined ADDI/SUBI Test Program
# This program tests both ADDI and SUBI in various combinations

main:
# Initialize base values
LOADI R1, #100 # R1 = 100 (base value)
LOADI R2, #0 # R2 = 0 (accumulator)

# Test arithmetic sequence with immediate operations
ADDI R2, R2, #10 # R2 = 10
SUBI R2, R2, #3 # R2 = 7
ADDI R2, R2, #8 # R2 = 15
SUBI R2, R2, #2 # R2 = 13

# Test with base register
ADDI R3, R1, #50 # R3 = 150 (100 + 50)
SUBI R4, R1, #25 # R4 = 75 (100 - 25)

# Test boundary conditions
ADDI R5, R0, #255 # R5 = 255 (max positive immediate)
SUBI R6, R5, #255 # R6 = 0 (should set zero flag)
ADDI R7, R0, #-256 # R7 = -256 (max negative immediate)
SUBI R8, R0, #-256 # R8 = 256 (subtract negative = add positive)

# Comparison with regular ADD/SUB
LOADI R9, #5 # R9 = 5 (for comparison)
ADD R10, R1, R9 # R10 = 105 (100 + 5 using ADD)
ADDI R11, R1, #5 # R11 = 105 (100 + 5 using ADDI)

SUB R12, R1, R9 # R12 = 95 (100 - 5 using SUB)
SUBI R13, R1, #5 # R13 = 95 (100 - 5 using SUBI)

# Test flag setting with immediate operations
ADDI R14, R0, #127 # R14 = 127
ADDI R14, R14, #127 # R14 = 254 (test positive overflow)

SUBI R15, R0, #1 # R15 = -1 (test negative flag)

# Store verification values
STORE R2, 0x6000 # Store 13
STORE R3, 0x6004 # Store 150
STORE R4, 0x6008 # Store 75
STORE R6, 0x600C # Store 0
STORE R8, 0x6010 # Store 256
STORE R10, 0x6014 # Store 105 (ADD result)
STORE R11, 0x6018 # Store 105 (ADDI result - should match)
STORE R12, 0x601C # Store 95 (SUB result)
STORE R13, 0x6020 # Store 95 (SUBI result - should match)

# Final test: increment/decrement pattern
LOADI R16, #0 # R16 = 0
ADDI R16, R16, #1 # R16 = 1
ADDI R16, R16, #1 # R16 = 2
ADDI R16, R16, #1 # R16 = 3
SUBI R16, R16, #1 # R16 = 2
SUBI R16, R16, #1 # R16 = 1
STORE R16, 0x6024 # Store 1

HALT
