# Subtract 5 numbers and store the result in r1

start:
addi x1, zero, 150 # r1 = 150 (accumulator, start high for visible result)

addi x2, zero, 10
sub x1, x1, x2 # r1 -= 10

addi x2, zero, 20
sub x1, x1, x2 # r1 -= 20

addi x2, zero, 30
sub x1, x1, x2 # r1 -= 30

addi x2, zero, 40
sub x1, x1, x2 # r1 -= 40

addi x2, zero, 50
sub x1, x1, x2 # r1 -= 50

ebreak # stop execution
