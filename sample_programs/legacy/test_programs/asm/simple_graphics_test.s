# Simple graphics test - write directly to framebuffer memory
# This test manually writes pixel data to test the framebuffer dumping

main:
# Write a few pixels directly to framebuffer memory at 0x800
# Pixel format: RRGGBB00 (RGB + alpha/padding)

# Write red pixel at position 0
addi x1, zero, 0x800 # Framebuffer base address (2048)
addi x2, zero, 0xFF000000 # Red pixel
sw x2, 0(x1)

# Write green pixel at position 1
add x1, x1, #4
addi x2, zero, 0x00FF0000 # Green pixel  
sw x2, 0(x1)

# Write blue pixel at position 2
add x1, x1, #4
addi x2, zero, 0x0000FF00 # Blue pixel
sw x2, 0(x1)

# Write yellow pixel at position 3
add x1, x1, #4
addi x2, zero, 0xFFFF0000 # Yellow pixel
sw x2, 0(x1)

# End program
ebreak
