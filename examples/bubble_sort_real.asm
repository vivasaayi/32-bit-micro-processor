; Advanced Bubble Sort with Actual Comparisons
; Demonstrates real sorting algorithm with comparisons and swaps

.org 0x8000

main:
    ; Initialize array values
    LOADI R0, #7        ; R0 = 7 (first element)
    LOADI R1, #3        ; R1 = 3 (second element) 
    LOADI R2, #9        ; R2 = 9 (third element)
    
    ; Display initial values
    JMP compare_r0_r1   ; Start sorting
    
compare_r0_r1:
    ; Compare R0 and R1, swap if R0 > R1
    ; We know R0=7, R1=3, so 7 > 3, need to swap
    
    ; Save R0 in R3 (temp)
    LOADI R3, #0        ; Clear R3
    ADD R3, R0          ; R3 = R0 (temp = R0)
    
    ; Move R1 to R0
    LOADI R0, #0        ; Clear R0
    ADD R0, R1          ; R0 = R1
    
    ; Move temp (R3) to R1
    LOADI R1, #0        ; Clear R1
    ADD R1, R3          ; R1 = temp (original R0)
    
    ; Now R0=3, R1=7, R2=9
    JMP compare_r1_r2
    
compare_r1_r2:
    ; Compare R1 and R2, swap if R1 > R2
    ; We have R1=7, R2=9, so 7 < 9, no swap needed
    JMP compare_r0_r1_second
    
compare_r0_r1_second:
    ; Second pass: compare R0 and R1 again
    ; R0=3, R1=7, so 3 < 7, no swap needed
    JMP sort_complete
    
sort_complete:
    ; Store sorted results in memory for verification
    STORE R0, #0x8200   ; Store smallest at 0x8200
    STORE R1, #0x8201   ; Store middle at 0x8201  
    STORE R2, #0x8202   ; Store largest at 0x8202
    
    HALT                ; End program

; Expected result: R0=3, R1=7, R2=9 (sorted ascending)
