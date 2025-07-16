; Add 5 numbers and store the result in r1

start:
    mov r1, #0       ; r1 = 0 (accumulator)
    
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

    halt             ; stop execution