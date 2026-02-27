# Fill the entire framebuffer with red (0xFF0000FF)
.org 0x8000

main:
LOADI R1, #888
LOADI R2, red_color # R2 Has Address of red_color  
LOAD R3, R2 # Red value, using address in R2


LOADI R4, #0x10000 # Frame Buffer base address
LOAD  R5, R4 # value in frame buffeer


# STORE Register R3 to address contained in register R4
STORE [R4], R3
LOAD R5, R4
LOAD R6, #0


# STORE Register to direct address
STORE R3, #0x10000
LOAD R8, R4

# Data section - placed after code
red_color:
.word 0xFF0000FF # 32-bit red color with alpha
