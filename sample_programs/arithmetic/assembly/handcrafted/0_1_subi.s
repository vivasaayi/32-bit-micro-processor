.global main

main:
# Test basic SUBI operations
addi x1, x0, 20       # x1 = 20
addi x2, x1, -5     # x2 = x1 - 5 = 15
addi x3, x2, -10    # x3 = x2 - 10 = 5
addi x4, x1, 0     # x4 = x1 - 0 = 20 (no change)

# Test with negative immediate (double negative = addition)
addi x5, x1, 3    # x5 = x1 - (-3) = 20 + 3 = 23

# Test edge cases
addi x6, x0, 10       # x6 = 10
addi x7, x6, -10    # x7 = 0 (should set zero flag)
addi x8, x6, -15    # x8 = -5 (negative result, should set negative flag)

# Test with maximum immediate values
addi x9, x0, 300      # x9 = 300
addi x10, x9, -255  # x10 = 300 - 255 = 45
addi x11, x9, 256 # x11 = 300 - (-256) = 556

# Chain SUBI operations
addi x12, x0, 100     # x12 = 100
addi x12, x12, -10  # x12 = 90
addi x12, x12, -20  # x12 = 70
addi x12, x12, -30  # x12 = 40

# Mixed ADDI and SUBI operations
addi x13, x0, 50      # x13 = 50
addi x13, x13, 25  # x13 = 75
addi x13, x13, -15  # x13 = 60
addi x13, x13, 5   # x13 = 65
addi x13, x13, -20  # x13 = 45

# Store results to memory for verification
sw x2, 0x5000(x0)    # Store 15
sw x3, 0x5004(x0)    # Store 5
sw x5, 0x5008(x0)    # Store 23
sw x7, 0x500C(x0)    # Store 0
sw x8, 0x5010(x0)    # Store -5
sw x12, 0x5014(x0)   # Store 40
sw x13, 0x5018(x0)   # Store 45

ebreak