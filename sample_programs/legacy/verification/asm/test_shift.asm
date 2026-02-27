# Comprehensive Shift Instructions Test
.org 0x0

# Setup test values
LI x1, 0x87654321 # rs1 = 0x87654321 (negative number)
LI x2, 4 # rs2 = 4 (shift amount)
LI x10, 0x2000 # Base address for results

# Shift Left Logical
SLL x3, x1, x2 # x3 = 0x87654321 << 4 = 0x76543210
SW x3, 0(x10)

SLLI x4, x1, 8 # x4 = 0x87654321 << 8 = 0x65432100
SW x4, 4(x10)

# Shift Right Logical
SRL x5, x1, x2 # x5 = 0x87654321 >> 4 = 0x08765432
SW x5, 8(x10)

SRLI x6, x1, 8 # x6 = 0x87654321 >> 8 = 0x00876543
SW x6, 12(x10)

# Shift Right Arithmetic
SRA x7, x1, x2 # x7 = 0x87654321 >>> 4 = 0xF8765432 (sign-extended)
SW x7, 16(x10)

SRAI x8, x1, 8 # x8 = 0x87654321 >>> 8 = 0xFF876543 (sign-extended)
SW x8, 20(x10)

# Test with positive number
LI x11, 0x12345678 # Positive number
SLL x12, x11, x2 # x12 = 0x12345678 << 4 = 0x23456780
SW x12, 24(x10)

SRL x13, x11, x2 # x13 = 0x12345678 >> 4 = 0x01234567
SW x13, 28(x10)

SRA x14, x11, x2 # x14 = 0x12345678 >>> 4 = 0x01234567 (same as SRL for positive)
SW x14, 32(x10)

# Test edge cases
LI x15, 0x80000000 # Most negative 32-bit number
SRAI x16, x15, 31 # x16 = 0x80000000 >>> 31 = 0xFFFFFFFF (-1)
SW x16, 36(x10)

LI x17, 0xFFFFFFFF # All 1s
SRLI x18, x17, 16 # x18 = 0xFFFFFFFF >> 16 = 0x0000FFFF
SW x18, 40(x10)

# Expected results at addresses:
# 0x2000: 0x76543210 (SLL)
# 0x2004: 0x65432100 (SLLI)
# 0x2008: 0x08765432 (SRL)
# 0x200C: 0x00876543 (SRLI)
# 0x2010: 0xF8765432 (SRA)
# 0x2014: 0xFF876543 (SRAI)
# 0x2018: 0x23456780 (SLL positive)
# 0x201C: 0x01234567 (SRL positive)
# 0x2020: 0x01234567 (SRA positive)
# 0x2024: 0xFFFFFFFF (SRAI edge case)
# 0x2028: 0x0000FFFF (SRLI edge case)

HALT