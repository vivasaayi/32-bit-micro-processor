; Enhanced Array Sorting Demonstration - 32-bit version
; Shows sorting concept with 32-bit values
; Demonstrates with 4 diverse elements scaled up

.org 0x8000

main:
    ; Initialize with unsorted 32-bit values
    LOADI R4, #1890000  ; Element 1 = 1,890,000 (very large) - was R0, but R0 is zero register
    LOADI R1, #120000   ; Element 2 = 120,000 (medium)  
    LOADI R2, #2550000  ; Element 3 = 2,550,000 (largest)
    LOADI R3, #100000   ; Element 4 = 100,000 (smallest)
    
    ; Store array in memory at 0x1200
    LOADI R5, #0x1200
    STORE R4, R5, #0    ; Store 1,890,000 at 0x1200
    STORE R1, R5, #4    ; Store 120,000 at 0x1204
    STORE R2, R5, #8    ; Store 2,550,000 at 0x1208
    STORE R3, R5, #12   ; Store 100,000 at 0x120C
    
    HALT
    ; Copy sorted results to output memory location 0x1250
    LOADI R8, #0x1250   ; Output address
    LOAD R9, R4, #0     ; Load sorted element 0
    STORE R9, R8, #0    ; Store at output
    LOAD R9, R4, #4     ; Load sorted element 1
    STORE R9, R8, #4    ; Store at output
    LOAD R9, R4, #8     ; Load sorted element 2
    STORE R9, R8, #8    ; Store at output
    LOAD R9, R4, #12    ; Load sorted element 3
    STORE R9, R8, #12   ; Store at output
    
    ; Load final results into registers for verification
    LOAD R10, R8, #0    ; R10 = smallest (should be 100,000)
    LOAD R11, R8, #4    ; R11 = second (should be 120,000)
    LOAD R12, R8, #8    ; R12 = third (should be 1,890,000)
    LOAD R13, R8, #12   ; R13 = largest (should be 2,550,000)
    
    HALT
