# Test ADDI (Add Immediate) Instruction
# This program tests adding immediate values to registers

_start:
# Test basic ADDI operations
addi x1, zero, 10 # x1 = 10
addi x2, x1, 5 # x2 = x1 + 5 = 15
addi x3, x2, -3 # x3 = x2 + (-3) = 12
addi x4, x0, 42 # x4 = x0 + 42 = 42 (x0 is always 0)

# Test with larger immediate values
addi x5, x0, 255 # x5 = 255 (max positive 9-bit immediate)
addi x6, x0, -256 # x6 = -256 (max negative 9-bit immediate)

# Chain ADDI operations
addi x7, x0, 1 # x7 = 1
addi x7, x7, 2 # x7 = 3
addi x7, x7, 4 # x7 = 7
addi x7, x7, 8 # x7 = 15

# Test flag effects (should set zero flag when result is 0)
addi x8, zero, 5 # x8 = 5
addi x9, x8, -5 # x9 = 0 (should set zero flag)

# Store results to memory for verification
lui t0, 0x4000
sw x2, 0(t0) # Store 15
sw x3, 4(t0) # Store 12
sw x4, 5(t0) # Store 42
sw x7, 12(t0) # Store 15
sw x9, 16(t0) # Store 0


