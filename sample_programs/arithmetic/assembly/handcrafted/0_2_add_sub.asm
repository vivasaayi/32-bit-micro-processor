# Comprehensive test: add 5 numbers, then subtract 5 numbers, store result in r1

start:
addi x1, zero, 0 # r1 = 0 (accumulator)

# Addition phase
addi x2, zero, 10
add x1, x1, x2 # r1 += 10

addi x2, zero, 20
add x1, x1, x2 # r1 += 20

addi x2, zero, 30
add x1, x1, x2 # r1 += 30

addi x2, zero, 40
add x1, x1, x2 # r1 += 40

addi x2, zero, 50
add x1, x1, x2 # r1 += 50

# Subtraction phase
addi x2, zero, 5
sub x1, x1, x2 # r1 -= 5

addi x2, zero, 10
sub x1, x1, x2 # r1 -= 10

addi x2, zero, 15
sub x1, x1, x2 # r1 -= 15

addi x2, zero, 20
sub x1, x1, x2 # r1 -= 20

addi x2, zero, 25
sub x1, x1, x2 # r1 -= 25

ebreak # stop execution (result 75)
