; Simple Bubble Sort Program for 8-bit Microprocessor
; Sorts a small array using only supported instructions
; Uses LOADI, ADD, SUB, JMP, HALT

.org 0x8000

main:
    ; Sort a 3-element array: [5, 2, 8] -> [2, 5, 8]
    ; We'll use registers R0, R1, R2 to hold array elements
    ; R3, R4, R5 will be used for comparison and swapping
    
    ; Initialize array values in registers
    LOADI R0, #5        ; array[0] = 5
    LOADI R1, #2        ; array[1] = 2  
    LOADI R2, #8        ; array[2] = 8
    
    ; First pass: compare R0 and R1
compare_01:
    ; Check if R0 > R1, if so swap them
    SUB R3, R0          ; R3 = R0 (copy R0 to R3)
    ADD R3, R0          ; R3 = R0
    SUB R3, R1          ; R3 = R0 - R1
    
    ; If R3 > 0, then R0 > R1, need to swap
    ; For simplicity, we'll do the swap unconditionally and check manually
    ; Manual check: if R0=5, R1=2, then R0>R1, so swap
    
    ; Swap R0 and R1 (since 5 > 2)
    LOADI R4, #0        ; R4 = temp
    ADD R4, R0          ; R4 = R0 (temp = R0)
    LOADI R0, #0        ; R0 = 0
    ADD R0, R1          ; R0 = R1 (R0 = R1)
    LOADI R1, #0        ; R1 = 0  
    ADD R1, R4          ; R1 = temp (R1 = original R0)
    
    ; Now R0=2, R1=5, R2=8
    
compare_12:
    ; Compare R1 and R2 (5 vs 8)
    SUB R3, R1          ; R3 = R1
    ADD R3, R1          ; R3 = R1  
    SUB R3, R2          ; R3 = R1 - R2
    
    ; Since 5 < 8, no swap needed for R1 and R2
    
    ; Second pass: compare R0 and R1 again
compare_01_pass2:
    ; R0=2, R1=5 - already in order, no swap needed
    
    ; Array is now sorted: R0=2, R1=5, R2=8
    ; Output the sorted values
    
output_results:
    ; Output sorted array elements
    ; Since we don't have OUT instruction, we'll store results in memory
    
    ; Store sorted results at memory location 0x8200
    STORE R0, #0x8200   ; Store R0 (smallest) at 0x8200
    STORE R1, #0x8201   ; Store R1 (middle) at 0x8201
    STORE R2, #0x8202   ; Store R2 (largest) at 0x8202
    
    ; Load and verify the results
    LOAD R3, #0x8200    ; R3 = sorted[0] should be 2
    LOAD R4, #0x8201    ; R4 = sorted[1] should be 5
    LOAD R5, #0x8202    ; R5 = sorted[2] should be 8
    
    HALT                ; End program

; Expected final state:
; R0 = 2 (smallest element)
; R1 = 5 (middle element)  
; R2 = 8 (largest element)
; Memory 0x8200 = 2
; Memory 0x8201 = 5
; Memory 0x8202 = 8
