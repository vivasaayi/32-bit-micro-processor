# Hello World Program for 32-bit Microprocessor
# Demonstrates basic I/O and string output capabilities

.org 0x8000

start:
# Simple hello world values
LOADI R4, #0x48656C6C # "Hell" - was R0, but R0 is zero register  
LOADI R1, #0x6F20576F # "o Wo"
LOADI R2, #0x726C6421 # "rld!"

# Store message in memory at 0x6000
LOADI R10, #0x6000
STORE R4, R10, #0
STORE R1, R10, #4
STORE R2, R10, #8

HALT