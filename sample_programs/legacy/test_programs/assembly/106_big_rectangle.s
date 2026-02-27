# Big Rectangle Graphics Test
# Draw a large filled rectangle on screen

.text
.globl _start

_start:
    # Initialize framebuffer base address
    # Framebuffer starts at 0x50000 (320KB base)
    lui t0, 0x50        # Load upper immediate: 0x50000
    
    # Screen dimensions: 64x64 pixels
    # Each pixel is 1 byte (8-bit color)
    # Total framebuffer size: 64 * 64 = 4096 bytes
    
    # Draw parameters for big rectangle
    # Rectangle from (10,10) to (54,54) - 44x44 pixel rectangle
    # Color: 0xFF (white/bright)
    
    li t1, 10           # start_x = 10
    li t2, 10           # start_y = 10
    li t3, 54           # end_x = 54
    li t4, 54           # end_y = 54
    li t5, 0xFF         # color = bright white
    
    # Clear screen first (set all to black)
    mv a0, t0           # framebuffer base
    li a1, 4096         # total pixels
    li a2, 0x00         # black color
    jal clear_screen
    
    # Draw the big rectangle
    mv a0, t0           # framebuffer base
    mv a1, t1           # start_x
    mv a2, t2           # start_y  
    mv a3, t3           # end_x
    mv a4, t4           # end_y
    mv a5, t5           # color
    jal draw_rectangle
    
    # Draw border around the rectangle in different color
    li t5, 0x7F         # gray color for border
    mv a0, t0           # framebuffer base
    li a1, 9            # border start_x = 9
    li a2, 9            # border start_y = 9
    li a3, 55           # border end_x = 55
    li a4, 55           # border end_y = 55
    mv a5, t5           # border color
    jal draw_border
    
    # Infinite loop to keep program running
loop:
    j loop

# Function: clear_screen
# a0 = framebuffer base
# a1 = number of pixels
# a2 = color
clear_screen:
    mv t0, a0           # current address
    mv t1, a1           # pixel count
    mv t2, a2           # color
clear_loop:
    beqz t1, clear_done
    sb t2, 0(t0)        # store color byte
    addi t0, t0, 1      # next pixel
    addi t1, t1, -1     # decrement counter
    j clear_loop
clear_done:
    jr ra

# Function: draw_rectangle  
# a0 = framebuffer base
# a1 = start_x
# a2 = start_y
# a3 = end_x  
# a4 = end_y
# a5 = color
draw_rectangle:
    mv t0, a0           # framebuffer base
    mv t1, a1           # start_x
    mv t2, a2           # start_y
    mv t3, a3           # end_x
    mv t4, a4           # end_y
    mv t5, a5           # color
    
    mv t6, t2           # current_y = start_y
rect_y_loop:
    bge t6, t4, rect_done    # if current_y >= end_y, done
    mv t7, t1           # current_x = start_x
rect_x_loop:
    bge t7, t3, rect_next_row # if current_x >= end_x, next row
    
    # Calculate pixel address: base + (y * 64 + x)
    slli s0, t6, 6      # y * 64 (shift left by 6 = multiply by 64)
    add s0, s0, t7      # y * 64 + x
    add s0, s0, t0      # framebuffer_base + offset
    
    sb t5, 0(s0)        # store color at pixel
    
    addi t7, t7, 1      # current_x++
    j rect_x_loop
rect_next_row:
    addi t6, t6, 1      # current_y++
    j rect_y_loop
rect_done:
    jr ra

# Function: draw_border
# a0 = framebuffer base  
# a1 = start_x
# a2 = start_y
# a3 = end_x
# a4 = end_y
# a5 = color
draw_border:
    mv t0, a0           # framebuffer base
    mv t1, a1           # start_x
    mv t2, a2           # start_y  
    mv t3, a3           # end_x
    mv t4, a4           # end_y
    mv t5, a5           # color
    
    # Draw top border
    mv t6, t1           # current_x = start_x
border_top:
    bge t6, t3, border_bottom_start
    slli s0, t2, 6      # start_y * 64
    add s0, s0, t6      # start_y * 64 + current_x
    add s0, s0, t0      # framebuffer_base + offset
    sb t5, 0(s0)        # store color
    addi t6, t6, 1      # current_x++
    j border_top
    
border_bottom_start:
    mv t6, t1           # current_x = start_x
border_bottom:
    bge t6, t3, border_left_start
    slli s0, t4, 6      # end_y * 64
    add s0, s0, t6      # end_y * 64 + current_x
    add s0, s0, t0      # framebuffer_base + offset
    sb t5, 0(s0)        # store color
    addi t6, t6, 1      # current_x++
    j border_bottom
    
border_left_start:
    mv t6, t2           # current_y = start_y
border_left:
    bge t6, t4, border_right_start
    slli s0, t6, 6      # current_y * 64
    add s0, s0, t1      # current_y * 64 + start_x
    add s0, s0, t0      # framebuffer_base + offset
    sb t5, 0(s0)        # store color
    addi t6, t6, 1      # current_y++
    j border_left
    
border_right_start:
    mv t6, t2           # current_y = start_y
border_right:
    bge t6, t4, border_done
    slli s0, t6, 6      # current_y * 64
    add s0, s0, t3      # current_y * 64 + end_x
    add s0, s0, t0      # framebuffer_base + offset
    sb t5, 0(s0)        # store color
    addi t6, t6, 1      # current_y++
    j border_right
    
border_done:
    jr ra
