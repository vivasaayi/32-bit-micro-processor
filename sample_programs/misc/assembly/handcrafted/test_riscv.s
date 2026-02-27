addi x1, x0, 10
addi x2, x0, 20
add x3, x1, x2
sw x3, 0(x0)
lw x4, 0(x0)
beq x3, x4, label
addi x5, x0, 1
label:
addi x6, x0, 2