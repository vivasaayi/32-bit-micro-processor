.global main

.org 0x8000

main:
li x9, 0x10000    # framebuffer base address
li x10, 76800     # total pixels (320*240)

# Load the full 32-bit color from data section
la x13, red_color  # Address of red_color
lw x11, 0(x13)         # Load the full 32-bit value

addi x12, x0, 0         # pixel counter
add x12, x12, x9      # start address

fill_loop:
add x29, x12, x0 # COPY # START ADDRESS IN R29 for debugging

# STORE Register R11 (Red Pixel) to address contained in register R12
sw x11, 0(x12)          # store red pixel


lw x30, 0(x12)           # load back to verify store worked

addi x12, x12, 4      # next pixel (4 bytes per pixel)
addi x10, x10, -1      # decrement pixel count
beq x10, x0, fill_done
j fill_loop

fill_done:
ebreak

# Data section - placed after code
.data
red_color:
.word 0xFF0000FF     # 32-bit red color with alpha