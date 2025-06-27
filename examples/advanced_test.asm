; Advanced test program demonstrating various 32-bit CPU features; Tests loops, conditional operations, and complex arithmetic.org 0x8000main:    ; Initialize counter    LOADI R0, #0       ; R0 = counter = 0    LOADI R1, #5       ; R1 = limit = 5    LOADI R2, #0       ; R2 = sum = 0loop:    ; Add counter to sum    ADD R2, R2, R0     ; sum += counter        ; Increment counter    ADDI R0, R0, #1    ; counter++        ; Check if counter < limit    SUB R3, R0, R1     ; R3 = counter - limit    BNZ continue       ; if (counter != limit) continue        ; Post-processing: sum = sum * 3 / 2    LOADI R4, #3    MUL R2, R2, R4     ; sum *= 3    LOADI R4, #2    DIV R2, R2, R4     ; sum /= 2        ; Store result in memory    LOADI R5, #0x4000    STORE R2, R5, #0   ; Store result at address 0x4000    
    ; Halt the processor
    HALT

continue:
    JMP loop           ; Go back to loop
