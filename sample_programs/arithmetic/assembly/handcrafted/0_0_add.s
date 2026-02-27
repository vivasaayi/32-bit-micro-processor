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

# Assert x1 == 155 (5+10+20+30+40+50)
li t0, 155
beq x1, t0, correct

# failure - print "FAIL\n"
lui t1, 0x10000  # UART base address
li t2, 'F'
sb t2, 0(t1)
li t2, 'A'
sb t2, 0(t1)
li t2, 'I'
sb t2, 0(t1)
li t2, 'L'
sb t2, 0(t1)
li t2, '\n'
sb t2, 0(t1)
j failure_loop

correct:
# success - print "PASS\n"
lui t1, 0x10000
li t2, 'P'
sb t2, 0(t1)
li t2, 'A'
sb t2, 0(t1)
li t2, 'S'
sb t2, 0(t1)
li t2, 'S'
sb t2, 0(t1)
li t2, '\n'
sb t2, 0(t1)

inf_loop:
    j inf_loop

failure_loop:
    j failure_loop