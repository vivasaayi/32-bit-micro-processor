.org 0x8000
# 108_bouncing_rectangle.asm - Animated bouncing rectangle
# Creates a rectangle that moves across the screen and bounces off edges

main:
# Debug marker - program started
addi x21, zero, 0xCAFEBABE
addi x20, zero, 0x5000
sw x21, 0(x20)

# Initialize rectangle parameters
addi x1, zero, 50 # rect_x (starting X position)
addi x2, zero, 30 # rect_y (starting Y position)
addi x3, zero, 20 # rect_width
addi x4, zero, 15 # rect_height
addi x5, zero, 2 # velocity_x (pixels per frame)
addi x6, zero, 1 # velocity_y (pixels per frame)

# Screen bounds
addi x7, zero, 320 # screen_width
addi x8, zero, 240 # screen_height

addi x9, zero, 128
add x9, x9, x9 # 256
add x9, x9, x9 # 512
add x9, x9, x9 # 1024
add x9, x9, x9 # 2048 (0x800) framebuffer base

addi x10, zero, 10000
addi x14, zero, 7
mov x15, x10
add_76k_loop:
add x10, x10, x15
sub x14, x14, #1
#cmp x14, #0
bne add_76k_loop
addi x14, zero, 6800
add x10, x10, x14

addi x11, zero, 0xFF # background color (0x000000FF)

animation_loop:
# Clear the entire screen first
mov x12, x9 # framebuffer base
mov x14, x10 # total pixels
clear_loop:
sw x11, 0(x12)
add x12, x12, #4
sub x14, x14, #1
#cmp x14, #0
bne clear_loop

# Draw the rectangle at current position
mov x16, x2 # current_y = rect_y
mov x15, x4 # rows_left = rect_height

draw_rows:
# Calculate start address for this row: fb_base + (current_y * 320 + rect_x) * 4
mov x17, x16 # current_y
addi x18, zero, 320
mul x17, x17, x18 # current_y * 320
add x17, x17, x1 # + rect_x
addi x18, zero, 4
mul x17, x17, x18 # * 4 (bytes per pixel)
add x17, x17, x9 # + framebuffer base

# Draw pixels in this row
mov x18, x3 # pixels_left = rect_width
addi x13, zero, 0xFF # r13 = 0x000000FF
add x13, x13, x13 # r13 = 0x000001FE
add x13, x13, x13 # r13 = 0x000003FC
add x13, x13, x13 # r13 = 0x000007F8
add x13, x13, x13 # r13 = 0x00000FF0
add x13, x13, x13 # r13 = 0x00001FE0
add x13, x13, x13 # r13 = 0x00003FC0
add x13, x13, x13 # r13 = 0x00007F80
add x13, x13, x13 # r13 = 0x0000FF00
add x13, x13, x13 # r13 = 0x0001FE00
add x13, x13, x13 # r13 = 0x0003FC00
add x13, x13, x13 # r13 = 0x0007F800
add x13, x13, x13 # r13 = 0x000FF000
add x13, x13, x13 # r13 = 0x001FE000
add x13, x13, x13 # r13 = 0x003FC000
add x13, x13, x13 # r13 = 0x007F8000
add x13, x13, x13 # r13 = 0x00FF0000
add x13, x13, x13 # r13 = 0x01FE0000
add x13, x13, x13 # r13 = 0x03FC0000
add x13, x13, x13 # r13 = 0x07F80000
add x13, x13, x13 # r13 = 0x0FF00000
add x13, x13, x13 # r13 = 0x1FE00000
add x13, x13, x13 # r13 = 0x3FC00000
add x13, x13, x13 # r13 = 0x7F800000
add x13, x13, x13 # r13 = 0xFF000000
addi x19, zero, 0xFF # r19 = 0x000000FF
add x13, x13, x19 # r13 = 0xFF0000FF (red)

draw_pixels:
sw x13, 0(x17)
add x17, x17, #4 # next pixel
sub x18, x18, #1
#cmp x18, #0
bne draw_pixels

# Next row
add x16, x16, #1 # current_y++
sub x15, x15, #1 # rows_left--
#cmp x15, #0
bne draw_rows

# Update position
add x1, x1, x5 # rect_x += velocity_x
add x2, x2, x6 # rect_y += velocity_y

# Check X bounds and bounce
#cmp x1, #0 # if rect_x < 0
beq not_less_x
j bounce_left
not_less_x:
add x19, x1, x3 # rect_x + rect_width
#cmp x19, x7 # if (rect_x + width) >= screen_width
beq bounce_right # if equal, branch
j check_y_bounds # if less, skip bounce_right
bounce_right:
sub x1, x7, x3 # rect_x = screen_width - rect_width
sub x5, x0, x5 # velocity_x = -velocity_x (flip sign)
j check_y_bounds

bounce_left:
addi x1, zero, 0 # rect_x = 0
sub x5, x0, x5 # velocity_x = -velocity_x (flip sign)

check_y_bounds:
#cmp x2, #0 # if rect_y < 0
beq not_less_y
j bounce_top
not_less_y:
add x19, x2, x4 # rect_y + rect_height
#cmp x19, x8 # if (rect_y + height) >= screen_height
beq bounce_bottom
j frame_delay
bounce_bottom:
sub x2, x8, x4 # rect_y = screen_height - rect_height
sub x6, x0, x6 # velocity_y = -velocity_y (flip sign)
j frame_delay

bounce_top:
addi x2, zero, 0 # rect_y = 0
sub x6, x0, x6 # velocity_y = -velocity_y (flip sign)

frame_delay:
addi x22, zero, 100 # r22 = 100
addi x17, zero, 100 # r17 = 100 (was r18)
mul x22, x22, x17 # r22 = 10,000
addi x17, zero, 9 # loop counter (was r18)
mov x19, x22 # r19 = 10,000 (constant)
delay_add_loop:
add x22, x22, x19 # r22 += 10,000
sub x17, x17, #1 # (was r18)
#cmp x17, #0 # (was r18)
bne delay_add_loop # repeat 9 times, r22 = 100,000

# Debug marker - frame completed
addi x20, zero, 0x5004
add x21, x21, #1 # increment frame counter
sw x21, 0(x20)

# Continue animation (infinite loop)
j animation_loop

end_program:
ebreak
