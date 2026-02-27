# Memory Verification Test
# Tests: SW, LW, SB, LB (if supported), etc.

.org 0x0
LI s0, 0x2000 # Status address
LI s1, 0x1000 # Test memory region base

# Test Word Access
LI t1, 0xDEADBEEF
SW t1, 0(s1)
LW t2, 0(s1)
BNE t1, t2, fail

# Test Offset addressing
LI t3, 0xCAFEBABE
SW t3, 4(s1)
LW t4, 4(s1)
BNE t3, t4, fail

# Verify no overwrite
LW t2, 0(s1)
LI t1, 0xDEADBEEF
BNE t1, t2, fail

# Test Byte Access (if supported, assuming Little Endian)
# Clear 0x1008
SW zero, 8(s1)

LI t1, 0x55
SB t1, 8(s1) # Write byte at 0x1008
LB t2, 8(s1) # Read back
BNE t1, t2, fail

# Check full word is 0x00000055
LW t3, 8(s1)
BNE t3, t1, fail

# Write another byte at 0x1009
LI t1, 0xAA
SB t1, 9(s1)

# Check word is now 0x0000AA55
LW t3, 8(s1)
LI t4, 0x0000AA55
BNE t3, t4, fail

# PASS
LI t1, 1
SW t1, 0(s0)
HALT

fail:
LI t1, 0
SW t1, 0(s0)
HALT
