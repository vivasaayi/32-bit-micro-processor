; Simplified Array Sorting Demonstration
; Shows sorting concept with working instruction set

.org 0x8000

main:
    ; Initialize with unsorted values 
    LOADI R0, #8        ; Element 1 = 8 (largest)
    LOADI R1, #3        ; Element 2 = 3 (smallest)  
    LOADI R2, #6        ; Element 3 = 6 (middle)
    
    ; Manual sorting: move smallest to R0, middle to R1, largest to R2
    ; Current: R0=8, R1=3, R2=6
    ; Target:  R0=3, R1=6, R2=8
    
    ; Step 1: Move R1 (3) to R3 temporarily
    LOADI R3, #0
    ADD R3, R1          ; R3 = 3
    
    ; Step 2: Move R2 (6) to R1  
    LOADI R1, #0
    ADD R1, R2          ; R1 = 6
    
    ; Step 3: Move R0 (8) to R2
    LOADI R2, #0  
    ADD R2, R0          ; R2 = 8
    
    ; Step 4: Move R3 (3) to R0
    LOADI R0, #0
    ADD R0, R3          ; R0 = 3
    
    ; Now sorted: R0=3, R1=6, R2=8
    HALT
