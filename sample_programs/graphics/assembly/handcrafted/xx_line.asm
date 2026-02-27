# Draw a horizontal line at y=100 from x=50 to x=270 (width 220)
.org 0x8000

main:
LOADI R9, #0 # framebuffer base address
LOADI R7, #320 # screen width
LOADI R8, #100 # y position
LOADI R1, #50 # x start
LOADI R2, #270 # x end (exclusive)
LOADI R13, #0xFF00FF # color (red + alpha)

# Calculate start address: fb_base + (y * 320 + x_start) * 4
LOADI R10, #0
ADD R10, R10, R8 # y
LOADI R11, #320
# y * 320 using shifts/adds (320 = 256 + 64)
LOADI R12, #0
ADD R12, R12, R10 # temp = y
ADD R12, R12, R12 # *2
ADD R12, R12, R12 # *4
ADD R12, R12, R12 # *8
ADD R12, R12, R12 # *16
ADD R12, R12, R12 # *32
ADD R12, R12, R12 # *64
LOADI R11, #0
ADD R11, R11, R12 # R11 = y*64
ADD R12, R12, R12 # *128
ADD R12, R12, R12 # *256
ADD R11, R11, R12 # R11 = y*320

ADD R11, R11, R1 # + x_start
ADD R11, R11, R11 # *2
ADD R11, R11, R11 # *4 (bytes per pixel)
ADD R11, R11, R9 # + framebuffer base

draw_line:
CMP R1, R2
JGE line_done
STORE R13, R11
ADDI R11, R11, 4
ADDI R1, R1, 1
JMP draw_line

line_done:
HALT