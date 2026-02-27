.global main

main:
# Test basic ADDI operations
addi x1, x0, 10       # x1 = 10
addi x2, x1, 5     # x2 = x1 + 5 = 15
addi x3, x2, -3    # x3 = x2 + (-3) = 12
addi x4, x0, 42    # x4 = x0 + 42 = 42 (x0 is always 0)

# Test with larger immediate values
addi x5, x0, 255   # x5 = 255 (max positive 9-bit immediate)
addi x6, x0, -256  # x6 = -256 (max negative 9-bit immediate)

# Chain ADDI operations
addi x7, x0, 1     # x7 = 1
addi x7, x7, 2     # x7 = 3
addi x7, x7, 4     # x7 = 7
addi x7, x7, 8     # x7 = 15

# Test flag effects (should set zero flag when result is 0)
addi x8, x0, 5        # x8 = 5
addi x9, x8, -5    # x9 = 0 (should set zero flag)

# Store results to memory for verification
sw x2, 0x4000(x0)    # Store 15
sw x3, 0x4004(x0)    # Store 12
sw x4, 0x4008(x0)    # Store 42
sw x7, 0x400C(x0)    # Store 15
sw x9, 0x4010(x0)    # Store 0

ebreak