; Comprehensive test: add 5 numbers, then subtract 5 numbers, store result in r1

start:
    mov r1, #0       ; r1 = 0 (accumulator)

    ; Addition phase
    mov r2, #10
    add r1, r1, r2   ; r1 += 10

    mov r2, #20
    add r1, r1, r2   ; r1 += 20

    mov r2, #30
    add r1, r1, r2   ; r1 += 30

    mov r2, #40
    add r1, r1, r2   ; r1 += 40

    mov r2, #50
    add r1, r1, r2   ; r1 += 50

    ; Subtraction phase
    mov r2, #5
    sub r1, r1, r2   ; r1 -= 5

    mov r2, #10
    sub r1, r1, r2   ; r1 -= 10

    mov r2, #15
    sub r1, r1, r2   ; r1 -= 15

    mov r2, #20
    sub r1, r1, r2   ; r1 -= 20

    mov r2, #25
    sub r1, r1, r2   ; r1 -= 25

    halt             ; stop execution (result 75)
