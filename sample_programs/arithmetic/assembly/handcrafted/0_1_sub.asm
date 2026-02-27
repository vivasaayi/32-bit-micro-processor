; Subtract 5 numbers and store the result in r1

start:
    mov r1, #150      ; r1 = 150 (accumulator, start high for visible result)
    
    mov r2, #10
    sub r1, r1, r2    ; r1 -= 10

    mov r2, #20
    sub r1, r1, r2    ; r1 -= 20

    mov r2, #30
    sub r1, r1, r2    ; r1 -= 30

    mov r2, #40
    sub r1, r1, r2    ; r1 -= 40

    mov r2, #50
    sub r1, r1, r2    ; r1 -= 50

    halt              ; stop execution
