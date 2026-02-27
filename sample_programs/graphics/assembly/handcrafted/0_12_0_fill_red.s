# Fill the entire framebuffer with red (0xFF0000FF)
.org 0x8000

main:
LOADI R9, #0x10000 # framebuffer base address
LOADI R10, #76800 # total pixels (320*240)

# Load the full 32-bit color from data section
LOADI R13, red_color # Address of red_color  
LOAD R11, R13 # Load the full 32-bit value

LOADI R12, #0 # pixel counter
ADD R12, R12, R9 # start address

fill_loop:
ADD R29, R12, R0 # COPY ; START ADDRESS IN R29 for debugging

# STORE Register R11 (Red Pixel) to address contained in register R12
STORE [R12], R11 # store red pixel


LOAD R30, R12 # load back to verify store worked

ADDI R12, R12, 4 # next pixel (4 bytes per pixel)
SUBI R10, R10, 1 # decrement pixel count
CMP R10, R0
JZ fill_done
JMP fill_loop

fill_done:
HALT

# Data section - placed after code
red_color:
.word 0xFF0000FF # 32-bit red color with alpha
