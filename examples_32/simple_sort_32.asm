; 32-bit Microprocessor Test Program
; Demonstrates basic 32-bit operations and sorting

.org 0x00000000

main:
    ; Test basic 32-bit arithmetic
    LOADI R1, #1000000      ; Load large number into R1
    LOADI R2, #2000000      ; Load large number into R2
    ADD R3, R1, R2          ; R3 = R1 + R2 = 3,000,000
    
    ; Test subtraction
    LOADI R4, #5000000      ; Load 5,000,000
    SUB R5, R4, R3          ; R5 = 5,000,000 - 3,000,000 = 2,000,000
    
    ; Simple 32-bit bubble sort of 4 elements
    ; Array: [50000, 10000, 80000, 30000]
    ; Target: [10000, 30000, 50000, 80000]
    
    LOADI R6, #50000        ; Element 0 = 50,000
    LOADI R7, #10000        ; Element 1 = 10,000  
    LOADI R8, #80000        ; Element 2 = 80,000
    LOADI R9, #30000        ; Element 3 = 30,000
    
    ; Pass 1: Compare R6 and R7
    SUB R10, R6, R7         ; R10 = R6 - R7
    ; If R10 > 0, swap R6 and R7 (50000 > 10000, so swap)
    ; Swap using R11 as temp
    ADD R11, R6, R0         ; R11 = R6 (50000)
    ADD R6, R7, R0          ; R6 = R7 (10000)  
    ADD R7, R11, R0         ; R7 = R11 (50000)
    ; Now: [10000, 50000, 80000, 30000]
    
    ; Compare R7 and R8
    SUB R10, R7, R8         ; R10 = R7 - R8 = 50000 - 80000 (negative, no swap)
    ; No swap needed
    ; Still: [10000, 50000, 80000, 30000]
    
    ; Compare R8 and R9
    SUB R10, R8, R9         ; R10 = R8 - R9 = 80000 - 30000 (positive, swap)
    ; Swap R8 and R9
    ADD R11, R8, R0         ; R11 = R8 (80000)
    ADD R8, R9, R0          ; R8 = R9 (30000)
    ADD R9, R11, R0         ; R9 = R11 (80000)
    ; Now: [10000, 50000, 30000, 80000]
    
    ; Pass 2: Compare R6 and R7 (already sorted)
    ; Compare R7 and R8
    SUB R10, R7, R8         ; R10 = 50000 - 30000 (positive, swap)
    ; Swap R7 and R8
    ADD R11, R7, R0         ; R11 = R7 (50000)
    ADD R7, R8, R0          ; R7 = R8 (30000)
    ADD R8, R11, R0         ; R8 = R11 (50000)
    ; Now: [10000, 30000, 50000, 80000] - SORTED!
    
    ; Store results in memory for verification
    STORE R6, #0x1000       ; Store 10000 at address 0x1000
    STORE R7, #0x1004       ; Store 30000 at address 0x1004
    STORE R8, #0x1008       ; Store 50000 at address 0x1008
    STORE R9, #0x100C       ; Store 80000 at address 0x100C
    
    ; Load them back to verify
    LOAD R12, #0x1000       ; R12 should be 10000
    LOAD R13, #0x1004       ; R13 should be 30000
    LOAD R14, #0x1008       ; R14 should be 50000
    LOAD R15, #0x100C       ; R15 should be 80000
    
    HALT                    ; End program

; Expected final state:
; R6 = 10,000  (smallest)
; R7 = 30,000  (second)
; R8 = 50,000  (third)
; R9 = 80,000  (largest)
; R12-R15 should match R6-R9
; Memory 0x1000-0x100C contains sorted array
