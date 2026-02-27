# Simple memory test to verify read/write operations

.org 0x8000

# Write test values
LOADI R1, #42
STORE R1, #0x0100
LOADI R2, #99
STORE R2, #0x0104

# Read them back
LOAD R4, #0x0100
LOAD R5, #0x0104

# Write some different values
LOADI R3, #123
STORE R3, #0x0108
LOAD R6, #0x0108

HALT
