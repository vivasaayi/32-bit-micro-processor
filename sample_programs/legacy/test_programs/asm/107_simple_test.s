.org 0x8000
# WRajan Test: rite 8 colored pixels at the top-left of the framebuffer and verify each write

main:
addi x9, zero, 0x4000 # Debug address (not framebuffer)
addi x10, zero, 0xDEADBEEF # Unique debug value
sw x10, 0(x9)

addi x1, zero, 0x800 # Framebuffer base address (2048)

addi x2, zero, 0xFF000000 # Red
sw x2, 0(x1)
lw x3, 0(x1)
#cmp x3, x2
beq next1
ebreak # Halt if mismatch
next1:
add x1, x1, #4

addi x2, zero, 0x00FF0000 # Green
sw x2, 0(x1)
lw x3, 0(x1)
#cmp x3, x2
beq next2
ebreak
next2:
addi x9, zero, 0x4000 # Debug address (not framebuffer)
addi x10, zero, 0xDEADBEEF # Unique debug value
sw x10, 0(x9)

add x1, x1, #4

addi x2, zero, 0x0000FF00 # Blue
sw x2, 0(x1)
lw x3, 0(x1)
#cmp x3, x2
beq next3
ebreak
next3:
add x1, x1, #4

addi x2, zero, 0xFFFF0000 # Yellow
sw x2, 0(x1)
lw x3, 0(x1)
#cmp x3, x2
beq next4
ebreak
next4:
add x1, x1, #4

addi x2, zero, 0xFF00FF00 # Magenta
sw x2, 0(x1)
lw x3, 0(x1)
#cmp x3, x2
beq next5
ebreak
next5:
add x1, x1, #4

addi x2, zero, 0x00FFFF00 # Cyan
sw x2, 0(x1)
lw x3, 0(x1)
#cmp x3, x2
beq next6
ebreak
next6:
add x1, x1, #4

addi x2, zero, 0xFFFFFF00 # White
sw x2, 0(x1)
lw x3, 0(x1)
#cmp x3, x2
beq next7
ebreak
next7:
add x1, x1, #4

addi x2, zero, 0x80808000 # Gray
sw x2, 0(x1)
lw x3, 0(x1)
#cmp x3, x2
beq delay_loop
ebreak

# Delay loop to keep the pattern visible
delay_loop:
addi x8, zero, 10000000
wait_loop:
sub x8, x8, #1
#cmp x8, #0
beq end_program
j wait_loop

end_program:
ebreak