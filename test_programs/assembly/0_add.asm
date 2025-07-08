; Add 5 numbers and store the result in r0

start:
    mov r0, #0       ; r0 = 0 (accumulator)
    
    mov r1, #10
    add r0, r0, r1   ; r0 += 10

    mov r1, #20
    add r0, r0, r1   ; r0 += 20

    mov r1, #30
    add r0, r0, r1   ; r0 += 30

    mov r1, #40
    add r0, r0, r1   ; r0 += 40

    mov r1, #50
    add r0, r0, r1   ; r0 += 50

    halt             ; stop execution