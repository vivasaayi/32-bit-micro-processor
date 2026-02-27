# Simple Display Demo - Assembly
# Demonstrates text mode display output

.text
.globl _start

_start:
# Set up display in text mode
lui $t0, 0xFF00      # Load upper part of display base
ori $t1, $zero, 0    # Text mode = 0
sw $t1, 0($t0)       # Write to mode register

# Set up text buffer address
lui $t2, 0xFF00      # Load upper part
ori $t2, $t2, 0x1000 # Text buffer at 0xFF001000

# Write "HELLO" - each character is 16-bit (char + attribute)
ori $t3, $zero, 0x0F48  # 'H' with white on black (0xF4H)
sh $t3, 0($t2)

ori $t3, $zero, 0x0F45  # 'E'
sh $t3, 2($t2)

ori $t3, $zero, 0x0F4C  # 'L'
sh $t3, 4($t2)

ori $t3, $zero, 0x0F4C  # 'L'
sh $t3, 6($t2)

ori $t3, $zero, 0x0F4F  # 'O'
sh $t3, 8($t2)

# Write "DISPLAY" on second line (offset 80*2 = 160 bytes)
ori $t3, $zero, 0x0A44  # 'D' with light green
sh $t3, 160($t2)

ori $t3, $zero, 0x0A49  # 'I'
sh $t3, 162($t2)

ori $t3, $zero, 0x0A53  # 'S'
sh $t3, 164($t2)

ori $t3, $zero, 0x0A50  # 'P'
sh $t3, 166($t2)

ori $t3, $zero, 0x0A4C  # 'L'
sh $t3, 168($t2)

ori $t3, $zero, 0x0A41  # 'A'
sh $t3, 170($t2)

ori $t3, $zero, 0x0A59  # 'Y'
sh $t3, 172($t2)

# Switch to graphics mode
ori $t1, $zero, 1    # Graphics mode = 1
sw $t1, 0($t0)       # Write to mode register

# Set up graphics buffer
lui $t4, 0xFF00      # Load upper part
ori $t4, $t4, 0x2000 # Graphics buffer at 0xFF002000

# Draw simple pattern (50x50 square at position 100,100)
ori $t5, $zero, 100  # Y counter
ori $t6, $zero, 640  # Screen width

draw_loop_y:
ori $t7, $zero, 100  # X counter

draw_loop_x:
# Calculate pixel address: base + (y * 640 + x)
mult $t5, $t6        # y * 640
mflo $t8
add $t8, $t8, $t7    # + x
add $t9, $t4, $t8    # + base address

# Calculate color (simple pattern)
add $s0, $t5, $t7    # x + y
andi $s0, $s0, 0xFF  # Keep lower 8 bits
sb $s0, 0($t9)       # Store pixel

# Increment X
addi $t7, $t7, 1
slti $s1, $t7, 200   # Check if x < 200
bne $s1, $zero, draw_loop_x

# Increment Y
addi $t5, $t5, 1
slti $s1, $t5, 200   # Check if y < 200
bne $s1, $zero, draw_loop_y

# Infinite loop to keep display active
main_loop:
j main_loop

# End of program
ori $v0, $zero, 10   # Exit syscall
syscall
