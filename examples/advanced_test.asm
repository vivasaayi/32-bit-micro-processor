; Advanced test program demonstrating various CPU features
; Tests loops, conditional operations, and complex arithmetic

.org 0x8000

main:
    ; Initialize counter
    LOADI R0, #0       ; R0 = counter = 0
    LOADI R1, #5       ; R1 = limit = 5
    LOADI R2, #0       ; R2 = sum = 0

loop:
    ; Add counter to sum
    ADD R2, R0         ; sum += counter
    
    ; Increment counter  
    LOADI R3, #1       ; R3 = 1
    ADD R0, R3         ; counter++
    
    ; Check if counter < limit
    SUB R0, R1         ; temp = counter - limit
    JZ end             ; if (counter == limit) goto end
    
    ; Restore counter (since SUB modified R0)
    ADD R0, R1         ; counter = temp + limit
    JMP loop           ; goto loop

end:
    ; Output final sum (should be 0+1+2+3+4 = 10)
    OUT R2             ; output sum
    HALT               ; stop execution
