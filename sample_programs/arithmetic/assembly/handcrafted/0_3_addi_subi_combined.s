.global main

main:
# Initialize base values
addi x1, x0, 100      # x1 = 100 (base value)
addi x2, x0, 0        # x2 = 0 (accumulator)

# Test arithmetic sequence with immediate operations
addi x2, x2, 10    # x2 = 10
addi x2, x2, -3     # x2 = 7
addi x2, x2, 8     # x2 = 15
addi x2, x2, -2     # x2 = 13

# Test with base register
addi x3, x1, 50    # x3 = 150 (100 + 50)
addi x4, x1, -25    # x4 = 75 (100 - 25)

# Test boundary conditions
addi x5, x0, 255   # x5 = 255 (max positive immediate)
addi x6, x5, -255   # x6 = 0 (should set zero flag)
addi x7, x0, -256  # x7 = -256 (max negative immediate)
addi x8, x0, 256  # x8 = 256 (subtract negative = add positive)

# Comparison with regular ADD/SUB
addi x9, x0, 5        # x9 = 5 (for comparison)
add x10, x1, x9     # x10 = 105 (100 + 5 using ADD)
addi x11, x1, 5    # x11 = 105 (100 + 5 using ADDI)

sub x12, x1, x9     # x12 = 95 (100 - 5 using SUB)
addi x13, x1, -5    # x13 = 95 (100 - 5 using SUBI)

# Test flag setting with immediate operations
addi x14, x0, 127  # x14 = 127
addi x14, x14, 127 # x14 = 254 (test positive overflow)

addi x15, x0, -1    # x15 = -1 (test negative flag)

# Store verification values
sw x2, 0x6000(x0)    # Store 13
sw x3, 0x6004(x0)    # Store 150
sw x4, 0x6008(x0)    # Store 75
sw x6, 0x600C(x0)    # Store 0
sw x8, 0x6010(x0)    # Store 256
sw x10, 0x6014(x0)   # Store 105 (ADD result)
sw x11, 0x6018(x0)   # Store 105 (ADDI result - should match)
sw x12, 0x601C(x0)   # Store 95 (SUB result)
sw x13, 0x6020(x0)   # Store 95 (SUBI result - should match)

# Final test: increment/decrement pattern
addi x16, x0, 0       # x16 = 0
addi x16, x16, 1   # x16 = 1
addi x16, x16, 1   # x16 = 2
addi x16, x16, 1   # x16 = 3
addi x16, x16, -1   # x16 = 2
addi x16, x16, -1   # x16 = 1
sw x16, 0x6024(x0)   # Store 1

ebreak