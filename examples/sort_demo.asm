; Enhanced Array Sorting Demonstration - 32-bit version; Shows sorting concept with 32-bit values; Demonstrates with 4 diverse elements scaled up.org 0x8000main:    ; Initialize with unsorted 32-bit values    LOADI R0, #1890000  ; Element 1 = 1,890,000 (very large)    LOADI R1, #120000   ; Element 2 = 120,000 (medium)      LOADI R2, #2550000  ; Element 3 = 2,550,000 (largest)    LOADI R3, #100000   ; Element 4 = 100,000 (smallest)        ; Store array in memory at 0x1200    LOADI R4, #0x1200    STORE R0, R4, #0    ; Store 1,890,000 at 0x1200    STORE R1, R4, #4    ; Store 120,000 at 0x1204    STORE R2, R4, #8    ; Store 2,550,000 at 0x1208    STORE R3, R4, #12   ; Store 100,000 at 0x120C        ; Simple bubble sort for 4 elements    ; Pass 1: Compare adjacent pairs    LOAD R5, R4, #0     ; Load element 0    LOAD R6, R4, #4     ; Load element 1    SUB R7, R5, R6      ; Compare    BPL no_swap1        ; If positive, no swap needed        ; Swap elements 0 and 1    STORE R6, R4, #0    ; Store smaller in position 0    STORE R5, R4, #4    ; Store larger in position 1no_swap1:    ; Compare elements 1 and 2    LOAD R5, R4, #4     ; Load element 1    LOAD R6, R4, #8     ; Load element 2    SUB R7, R5, R6      ; Compare    BPL no_swap2        ; If positive, no swap needed        ; Swap elements 1 and 2    STORE R6, R4, #4    ; Store smaller in position 1    STORE R5, R4, #8    ; Store larger in position 2no_swap2:    ; Compare elements 2 and 3    LOAD R5, R4, #8     ; Load element 2    LOAD R6, R4, #12    ; Load element 3    SUB R7, R5, R6      ; Compare    BPL no_swap3        ; If positive, no swap needed        ; Swap elements 2 and 3    STORE R6, R4, #8    ; Store smaller in position 2    STORE R5, R4, #12   ; Store larger in position 3no_swap3:    ; Pass 2: Another pass to ensure full sorting    LOAD R5, R4, #0     ; Load element 0    LOAD R6, R4, #4     ; Load element 1    SUB R7, R5, R6      ; Compare    BPL no_swap4        ; If positive, no swap needed        ; Swap elements 0 and 1    STORE R6, R4, #0    ; Store smaller in position 0    STORE R5, R4, #4    ; Store larger in position 1no_swap4:    ; Compare elements 1 and 2    LOAD R5, R4, #4     ; Load element 1    LOAD R6, R4, #8     ; Load element 2    SUB R7, R5, R6      ; Compare    BPL no_swap5        ; If positive, no swap needed        ; Swap elements 1 and 2    STORE R6, R4, #4    ; Store smaller in position 1    STORE R5, R4, #8    ; Store larger in position 2no_swap5:
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
