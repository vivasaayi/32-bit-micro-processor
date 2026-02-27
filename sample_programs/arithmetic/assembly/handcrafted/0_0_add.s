# Add 5 numbers and store the result in x1

start:
addi x1, zero, 0 # x1 = 0 (accumulator)

addi x2, zero, 10
add x1, x1, x2 # x1 += 10

addi x2, zero, 20
add x1, x1, x2 # x1 += 20

addi x2, zero, 30
add x1, x1, x2 # x1 += 30

addi x2, zero, 40
add x1, x1, x2 # x1 += 40

addi x2, zero, 50
add x1, x1, x2 # x1 += 50

ebreak # stop execution