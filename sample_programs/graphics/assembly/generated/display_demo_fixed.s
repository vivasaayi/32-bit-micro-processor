# Display Demo for Custom RISC Processor
.org 0x8000

# Initialize stack pointer
LOADI R30, #0x000F0000

main:
# Set up display base address (0xFF000000)
LOADI R1, #0xFF000
SHL R1, R1, #16

# Set text mode (mode = 0)
LOADI R2, #0
STORE R2, R1, #0

# Set up text buffer address (0xFF001000)
LOADI R3, #0xFF001
SHL R3, R3, #16

# Write "HELLO" to text buffer
LOADI R4, #0x0F48
STORE R4, R3, #0

LOADI R4, #0x0F45
STORE R4, R3, #2

LOADI R4, #0x0F4C
STORE R4, R3, #4

LOADI R4, #0x0F4C
STORE R4, R3, #6

LOADI R4, #0x0F4F
STORE R4, R3, #8

# Switch to graphics mode (mode = 1)
LOADI R2, #1
STORE R2, R1, #0

# Keep running
main_loop:
JMP main_loop

HALT
