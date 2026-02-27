# Comprehensive Logical Instructions Test
.org 0x0

# Setup test values
LI x1, 0xAAAA5555 # rs1 = 0xAAAA5555 (alternating bits)
LI x2, 0xFF00FF00 # rs2 = 0xFF00FF00 (alternating bytes)
LI x10, 0x2000 # Base address for results

# AND operations
AND x3, x1, x2 # x3 = 0xAAAA5555 & 0xFF00FF00 = 0xAA005500
SW x3, 0(x10)

ANDI x4, x1, 0x0F0F # x4 = 0xAAAA5555 & 0x0F0F = 0x00000505
SW x4, 4(x10)

# NOT operation (pseudo-instruction)
NOT x5, x1 # x5 = ~0xAAAA5555 = 0x5555AAAA
SW x5, 8(x10)

# OR operations
OR x6, x1, x2 # x6 = 0xAAAA5555 | 0xFF00FF00 = 0xFFAAFF55
SW x6, 12(x10)

ORI x7, x1, 0xF0F0 # x7 = 0xAAAA5555 | 0xF0F0 = 0xAAAFF5F5
SW x7, 16(x10)

# XOR operations
XOR x8, x1, x2 # x8 = 0xAAAA5555 ^ 0xFF00FF00 = 0x55AA55A5
SW x8, 20(x10)

XORI x9, x1, 0xFFFF # x9 = 0xAAAA5555 ^ 0xFFFF = 0xAAAA5AAA
SW x9, 24(x10)

# Additional test with different values
LI x11, 0x12345678
LI x12, 0x87654321

AND x13, x11, x12 # x13 = 0x12345678 & 0x87654321 = 0x02244220
SW x13, 28(x10)

OR x14, x11, x12 # x14 = 0x12345678 | 0x87654321 = 0x97755779
SW x14, 32(x10)

XOR x15, x11, x12 # x15 = 0x12345678 ^ 0x87654321 = 0x95511559
SW x15, 36(x10)

# Expected results at addresses:
# 0x2000: 0xAA005500 (AND)
# 0x2004: 0x00000505 (ANDI)
# 0x2008: 0x5555AAAA (NOT)
# 0x200C: 0xFFAAFF55 (OR)
# 0x2010: 0xAAAFF5F5 (ORI)
# 0x2014: 0x55AA55A5 (XOR)
# 0x2018: 0xAAAA5AAA (XORI)
# 0x201C: 0x02244220 (AND different values)
# 0x2020: 0x97755779 (OR different values)
# 0x2024: 0x95511559 (XOR different values)

HALT