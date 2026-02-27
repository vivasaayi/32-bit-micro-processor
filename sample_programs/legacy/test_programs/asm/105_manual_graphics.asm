# 105_manual_graphics.asm - Large yellow rectangle drawing test
# Draw a 8x6 rectangle in the framebuffer using basic operations

main:
# Setup
addi x1, zero, 0x800 # Framebuffer base address (2048)
addi x2, zero, 0xFF00 # Pixel color (yellow: fits in immediate field)

# Draw larger rectangle manually - 8 pixels wide, 6 pixels tall
# Row 0: pixels 0-7
sw x2, 0(x1) # Pixel (0,0)
add x1, x1, #4 # Next pixel
sw x2, 0(x1) # Pixel (1,0)
add x1, x1, #4 # Next pixel
sw x2, 0(x1) # Pixel (2,0)
add x1, x1, #4 # Next pixel
sw x2, 0(x1) # Pixel (3,0)
add x1, x1, #4 # Next pixel
sw x2, 0(x1) # Pixel (4,0)
add x1, x1, #4 # Next pixel
sw x2, 0(x1) # Pixel (5,0)
add x1, x1, #4 # Next pixel
sw x2, 0(x1) # Pixel (6,0)
add x1, x1, #4 # Next pixel
sw x2, 0(x1) # Pixel (7,0)

# Move to start of next row
add x1, x1, #4 # Move to next position

# Row 1: pixels 8-15
sw x2, 0(x1) # Pixel (0,1)
add x1, x1, #4 # Next pixel
sw x2, 0(x1) # Pixel (1,1)
add x1, x1, #4 # Next pixel
sw x2, 0(x1) # Pixel (2,1)
add x1, x1, #4 # Next pixel
sw x2, 0(x1) # Pixel (3,1)
add x1, x1, #4 # Next pixel
sw x2, 0(x1) # Pixel (4,1)
add x1, x1, #4 # Next pixel
sw x2, 0(x1) # Pixel (5,1)
add x1, x1, #4 # Next pixel
sw x2, 0(x1) # Pixel (6,1)
add x1, x1, #4 # Next pixel
sw x2, 0(x1) # Pixel (7,1)

# Move to start of next row
add x1, x1, #4 # Move to next position

# Row 2: pixels 16-23
sw x2, 0(x1) # Pixel (0,2)
add x1, x1, #4 # Next pixel
sw x2, 0(x1) # Pixel (1,2)
add x1, x1, #4 # Next pixel
sw x2, 0(x1) # Pixel (2,2)
add x1, x1, #4 # Next pixel
sw x2, 0(x1) # Pixel (3,2)
add x1, x1, #4 # Next pixel
sw x2, 0(x1) # Pixel (4,2)
add x1, x1, #4 # Next pixel
sw x2, 0(x1) # Pixel (5,2)
add x1, x1, #4 # Next pixel
sw x2, 0(x1) # Pixel (6,2)
add x1, x1, #4 # Next pixel
sw x2, 0(x1) # Pixel (7,2)

# Move to start of next row
add x1, x1, #4 # Move to next position

# Row 3: pixels 24-31
sw x2, 0(x1) # Pixel (0,3)
add x1, x1, #4 # Next pixel
sw x2, 0(x1) # Pixel (1,3)
add x1, x1, #4 # Next pixel
sw x2, 0(x1) # Pixel (2,3)
add x1, x1, #4 # Next pixel
sw x2, 0(x1) # Pixel (3,3)
add x1, x1, #4 # Next pixel
sw x2, 0(x1) # Pixel (4,3)
add x1, x1, #4 # Next pixel
sw x2, 0(x1) # Pixel (5,3)
add x1, x1, #4 # Next pixel
sw x2, 0(x1) # Pixel (6,3)
add x1, x1, #4 # Next pixel
sw x2, 0(x1) # Pixel (7,3)

# Move to start of next row
add x1, x1, #4 # Move to next position

# Row 4: pixels 32-39
sw x2, 0(x1) # Pixel (0,4)
add x1, x1, #4 # Next pixel
sw x2, 0(x1) # Pixel (1,4)
add x1, x1, #4 # Next pixel
sw x2, 0(x1) # Pixel (2,4)
add x1, x1, #4 # Next pixel
sw x2, 0(x1) # Pixel (3,4)
add x1, x1, #4 # Next pixel
sw x2, 0(x1) # Pixel (4,4)
add x1, x1, #4 # Next pixel
sw x2, 0(x1) # Pixel (5,4)
add x1, x1, #4 # Next pixel
sw x2, 0(x1) # Pixel (6,4)
add x1, x1, #4 # Next pixel
sw x2, 0(x1) # Pixel (7,4)

# Move to start of next row
add x1, x1, #4 # Move to next position

# Row 5: pixels 40-47
sw x2, 0(x1) # Pixel (0,5)
add x1, x1, #4 # Next pixel
sw x2, 0(x1) # Pixel (1,5)
add x1, x1, #4 # Next pixel
sw x2, 0(x1) # Pixel (2,5)
add x1, x1, #4 # Next pixel
sw x2, 0(x1) # Pixel (3,5)
add x1, x1, #4 # Next pixel
sw x2, 0(x1) # Pixel (4,5)
add x1, x1, #4 # Next pixel
sw x2, 0(x1) # Pixel (5,5)
add x1, x1, #4 # Next pixel
sw x2, 0(x1) # Pixel (6,5)
add x1, x1, #4 # Next pixel
sw x2, 0(x1) # Pixel (7,5)

# End program
ebreak
