.org 0x8000
# Fill the entire framebuffer with a single color (solid red), using word addressing

main:
# Debug marker - program started
addi x20, zero, 0x4000
addi x21, zero, 0xCAFEBABE
sw x21, 0(x20)

# Initialize framebuffer base address (word address)
addi x12, zero, 0x800 # Framebuffer base (word address)
addi x13, zero, 76800 # Total pixels (words)

# Build solid red color (0xFF000000) in r2
addi x2, zero, 0xFF
add x2, x2, x2 # 0x1FE
add x2, x2, x2 # 0x3FC
add x2, x2, x2 # 0x7F8
add x2, x2, x2 # 0xFF0
add x2, x2, x2 # 0x1FE0
add x2, x2, x2 # 0x3FC0
add x2, x2, x2 # 0x7F80
add x2, x2, x2 # 0xFF00
add x2, x2, x2 # 0x1FE00
add x2, x2, x2 # 0x3FC00
add x2, x2, x2 # 0x7F800
add x2, x2, x2 # 0xFF000
add x2, x2, x2 # 0x1FE000
add x2, x2, x2 # 0x3FC000
add x2, x2, x2 # 0x7F8000
add x2, x2, x2 # 0xFF0000
add x2, x2, x2 # 0x1FE0000
add x2, x2, x2 # 0x3FC0000
add x2, x2, x2 # 0x7F80000
add x2, x2, x2 # 0xFF00000
add x2, x2, x2 # 0x1FE00000
add x2, x2, x2 # 0x3FC00000
add x2, x2, x2 # 0x7F800000
add x2, x2, x2 # 0xFF000000

fill_loop:
sw x2, 0(x12)
add x12, x12, #1 # Next pixel (word address)
sub x13, x13, #1 # Pixels remaining
#cmp x13, #0
bne fill_loop

# Debug marker - program completed
addi x20, zero, 0x4004
addi x21, zero, 0xDEADBEEF
sw x21, 0(x20)

# Infinite loop to keep pattern visible
infinite_loop:
j infinite_loop

end_program:
ebreak
