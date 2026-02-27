# Comprehensive Test Program for 32-bit Microprocessor
# Tests arithmetic, logic, memory operations, and immediate values

.org 0x8000

main:
# Test immediate loading with large 32-bit values
LOADI R4, #100000 # R4 = 100000 (0x186A0) - was R0, but R0 is zero register
LOADI R1, #50000 # R1 = 50000 (0xC350)

# Test arithmetic operations
ADD R2, R4, R1 # R2 = 150000 (0x249F0)
SUB R3, R4, R1 # R3 = 50000

# Test memory operations
STORE R2, #0x3000 # Store 150000 at 0x3000

LOADI R11, #900000 # Large value (was 1200000, but that exceeds 20-bit limit)
STORE R11, #0x3004 # Store 900000 at 0x3004

# Load values back from memory
LOAD R12, #0x3000 # R12 = 150000 (from 0x3000)
LOAD R13, #0x3004 # R13 = 900000 (from 0x3004)

# Test immediate arithmetic
ADDI R14, R12, #5000 # R14 = 150000 + 5000 = 155000
SUBI R15, R13, #10000 # R15 = 1200000 - 10000 = 1190000

# Test logical operations
LOADI R4, #0xFF00FF00
LOADI R5, #0x00FF00FF
AND R6, R4, R5 # R6 = 0x00000000
OR R7, R4, R5 # R7 = 0xFFFFFFFF
XOR R8, R4, R5 # R8 = 0xFFFFFFFF

# Test shifts
LOADI R9, #1000
SLL R9, R9, #2 # R9 = 1000 << 2 = 4000
SRL R9, R9, #1 # R9 = 4000 >> 1 = 2000

HALT
