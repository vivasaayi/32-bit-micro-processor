.global start

start:
addi x1, x0, 0       # x1 = 0 (accumulator)

addi x2, x0, 10
add x1, x1, x2   # x1 += 10

addi x2, x0, 20
add x1, x1, x2   # x1 += 20

addi x2, x0, 30
add x1, x1, x2   # x1 += 30

addi x2, x0, 40
add x1, x1, x2   # x1 += 40

addi x2, x0, 50
add x1, x1, x2   # x1 += 50

ebreak             # stop execution