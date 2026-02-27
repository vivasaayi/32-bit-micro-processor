.global start

start:
addi x1, x0, 150      # x1 = 150 (accumulator, start high for visible result)

addi x2, x0, 10
sub x1, x1, x2    # x1 -= 10

addi x2, x0, 20
sub x1, x1, x2    # x1 -= 20

addi x2, x0, 30
sub x1, x1, x2    # x1 -= 30

addi x2, x0, 40
sub x1, x1, x2    # x1 -= 40

addi x2, x0, 50
sub x1, x1, x2    # x1 -= 50

ebreak              # stop execution