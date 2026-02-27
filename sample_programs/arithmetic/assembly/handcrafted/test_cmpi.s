# Test CMPI (Compare Immediate) instruction
# This tests comparing a register with an immediate value

main:
# Test 1: Compare with zero
addi R1, zero, 5
CMPI R1, #0 # Should set N=0, Z=0 (5 > 0)
sw R1, 0(0x8000) # R1 should still be 5

# Test 2: Compare with same value
addi R2, zero, 10
CMPI R2, #10 # Should set N=0, Z=1 (10 == 10)
sw R2, 0(0x8001) # R2 should still be 10

# Test 3: Compare with larger value
addi R3, zero, 3
CMPI R3, #8 # Should set N=1, Z=0 (3 < 8)
sw R3, 0(0x8002) # R3 should still be 3

# Test 4: Compare with negative immediate
addi R4, zero, 15
CMPI R4, #-5 # Should set N=0, Z=0 (15 > -5)
sw R4, 0(0x8003) # R4 should still be 15

HALT
