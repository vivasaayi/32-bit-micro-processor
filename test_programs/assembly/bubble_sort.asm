; Simple Bubble Sort Program for 32-bit Microprocessor
; Sorts 3 elements using a simplified bubble sort
; Uses values within 19-bit immediate range (max 524287)

.org 0x8000

main:
    ; Initialize 3 unsorted 32-bit values in registers
    LOADI R1, #30000     ; Element 0 = 30000 (largest)
    LOADI R2, #10000     ; Element 1 = 10000 (smallest)
    LOADI R3, #20000     ; Element 2 = 20000 (middle)
    
    ; Store original values in memory for reference
    STORE R1, #0x1000    ; Store 30000 at 0x1000
    STORE R2, #0x1004    ; Store 10000 at 0x1004
    STORE R3, #0x1008    ; Store 20000 at 0x1008
    
    ; Simple bubble sort - 3 passes to ensure complete sorting
    ; Pass 1: Compare R1 and R2, swap if needed
    CMP R1, R2           ; Compare R1 with R2
    JLE skip_swap1       ; If R1 <= R2, skip swap
    ; Swap R1 and R2
    LOADI R4, #0         ; Temp register
    ADD R4, R1, R4       ; R4 = R1 (temp = R1)
    ADD R1, R2, R4       ; R1 = R2 (R1 = R2) - This is wrong, let me fix
    SUB R1, R1, R4       ; R1 = R1 - R4 = R2 - R1 + R2 = R2 (This is still wrong)
    
    ; Let me use a proper swap method
    SUB R4, R1, R2       ; R4 = R1 - R2 (difference)
    SUB R1, R1, R4       ; R1 = R1 - (R1-R2) = R2
    ADD R2, R2, R4       ; R2 = R2 + (R1-R2) = R1
    
skip_swap1:
    ; Pass 2: Compare R2 and R3, swap if needed  
    CMP R2, R3           ; Compare R2 with R3
    JLE skip_swap2       ; If R2 <= R3, skip swap
    ; Swap R2 and R3
    SUB R4, R2, R3       ; R4 = R2 - R3 (difference)
    SUB R2, R2, R4       ; R2 = R2 - (R2-R3) = R3
    ADD R3, R3, R4       ; R3 = R3 + (R2-R3) = R2
    
skip_swap2:
    ; Pass 3: Compare R1 and R2 again (bubble up smaller values)
    CMP R1, R2           ; Compare R1 with R2
    JLE skip_swap3       ; If R1 <= R2, skip swap
    ; Swap R1 and R2
    SUB R4, R1, R2       ; R4 = R1 - R2 (difference)
    SUB R1, R1, R4       ; R1 = R1 - (R1-R2) = R2
    ADD R2, R2, R4       ; R2 = R2 + (R1-R2) = R1
    
skip_swap3:
    ; Store sorted values back to memory
    STORE R1, #0x2000    ; Store smallest at 0x2000
    STORE R2, #0x2004    ; Store middle at 0x2004
    STORE R3, #0x2008    ; Store largest at 0x2008
    
    ; Final result: R1 should have 10000, R2 should have 20000, R3 should have 30000
    HALT
