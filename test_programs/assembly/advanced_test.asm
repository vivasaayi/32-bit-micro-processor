; Advanced test program demonstrating loops and arithmetic
; Calculate sum of numbers from 0 to 4 (0+1+2+3+4 = 10)

.org 0x8000

start:
    ; Initialize registers
    LOADI R1, #5       ; R1 = limit value = 5
    LOADI R2, #0       ; R2 = sum = 0
    LOADI R3, #0       ; R3 = counter = 0

    ; Manual loop to calculate sum
loop_start:
    ; Check if counter has reached limit
    SUB R4, R1, R3     ; R4 = limit - counter
    ADDI R3, R3, #1    ; Increment counter first
    ADD R2, R2, R3     ; Add current counter to sum
    SUB R4, R1, R3     ; Check if we're done
    JEQ store_result   ; If R4 == 0, we're done

    ; Otherwise continue loop
    JMP loop_start

store_result:
    ; Store final sum (10) to memory
    STORE R2, #0x4000
    HALT
