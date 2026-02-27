# Test CMPI (Compare Immediate) instruction
# This tests comparing a register with an immediate value

main:
# Test 1: Compare with zero
LOADI R1, #5
CMPI R1, #0 # Should set N=0, Z=0 (5 > 0)
STORE R1, 0x8000 # R1 should still be 5

# Test 2: Compare with same value
LOADI R2, #10
CMPI R2, #10 # Should set N=0, Z=1 (10 == 10)
STORE R2, 0x8001 # R2 should still be 10

# Test 3: Compare with larger value
LOADI R3, #3
CMPI R3, #8 # Should set N=1, Z=0 (3 < 8)
STORE R3, 0x8002 # R3 should still be 3

# Test 4: Compare with negative immediate
LOADI R4, #15
CMPI R4, #-5 # Should set N=0, Z=0 (15 > -5)
STORE R4, 0x8003 # R4 should still be 15

HALT
