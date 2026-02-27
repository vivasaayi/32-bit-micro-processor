# Basic Operating System Kernel for 32-bit Microprocessor
# Demonstrates process management and system calls

.org 0x8000

kernel_init:
# Initialize kernel data structures
LOADI R15, #0x7FF0 # Kernel stack pointer
LOADI R14, #0x6000 # User stack base

# Create first process
LOADI R4, #user_process # was R0, but R0 is zero register
LOADI R1, #0x5000 # User process memory

# Simple computation
LOADI R2, #100000
LOADI R3, #200000
ADD R4, R2, R3 # R4 = 300000

# Store result
LOADI R5, #0x5100
STORE R4, R5, #0

HALT

user_process:
# Simple user process placeholder
LOADI R1, #12345
HALT