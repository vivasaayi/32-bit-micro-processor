; Bubble Sort Program for 32-bit Microprocessor
; Sorts 4 elements using bubble sort algorithm

.org 0x8000

main:
    ; Initialize 4 unsorted 32-bit values
    LOADI R0, #750000    ; Element 0 = 750000 (largest)
    LOADI R1, #100000    ; Element 1 = 100000 (second smallest)
    LOADI R2, #300000    ; Element 2 = 300000 (second largest) 
    LOADI R3, #50000     ; Element 3 = 50000 (smallest)
    
    ; Store array in memory at 0x5000
    LOADI R10, #0x5000   ; Array base address
    STORE R0, [R10 + 0]  ; Store 750000 at 0x5000
    STORE R1, [R10 + 4]  ; Store 100000 at 0x5004
    STORE R2, [R10 + 8]  ; Store 300000 at 0x5008
    STORE R3, [R10 + 12] ; Store 50000 at 0x500C
    
    ; Bubble sort: 3 passes for 4 elements
    ; Pass 1: Compare all adjacent pairs
    
    ; Compare elements 0 and 1
    LOAD R4, [R10 + 0]   ; Load element 0
    LOAD R5, [R10 + 4]   ; Load element 1
    SUB R6, R4, R5       ; Compare (element 0 - element 1)
    BPL no_swap_01       ; If positive, no swap needed
    
    ; Swap elements 0 and 1
    STORE R5, [R10 + 0]  ; Store smaller in position 0
    STORE R4, [R10 + 4]  ; Store larger in position 1

no_swap_01:
    ; Compare elements 1 and 2
    LOAD R4, [R10 + 4]   ; Load element 1
    LOAD R5, [R10 + 8]   ; Load element 2
    SUB R6, R4, R5       ; Compare
    BPL no_swap_12       ; If positive, no swap needed
    
    ; Swap elements 1 and 2
    STORE R5, [R10 + 4]  ; Store smaller in position 1
    STORE R4, [R10 + 8]  ; Store larger in position 2

no_swap_12:
    ; Compare elements 2 and 3
    LOAD R4, [R10 + 8]   ; Load element 2
    LOAD R5, [R10 + 12]  ; Load element 3
    SUB R6, R4, R5       ; Compare
    BPL no_swap_23       ; If positive, no swap needed
    
    ; Swap elements 2 and 3
    STORE R5, [R10 + 8]  ; Store smaller in position 2
    STORE R4, [R10 + 12] ; Store larger in position 3

no_swap_23:
    ; Pass 2: Compare first 2 pairs (largest already in place)
    
    ; Compare elements 0 and 1
    LOAD R4, [R10 + 0]
    LOAD R5, [R10 + 4]
    SUB R6, R4, R5
    BPL no_swap2_01
    STORE R5, [R10 + 0]
    STORE R4, [R10 + 4]

no_swap2_01:
    ; Compare elements 1 and 2
    LOAD R4, [R10 + 4]
    LOAD R5, [R10 + 8]
    SUB R6, R4, R5
    BPL no_swap2_12
    STORE R5, [R10 + 4]
    STORE R4, [R10 + 8]

no_swap2_12:
    ; Pass 3: Final comparison
    
    ; Compare elements 0 and 1
    LOAD R4, [R10 + 0]
    LOAD R5, [R10 + 4]
    SUB R6, R4, R5
    BPL sorted
    STORE R5, [R10 + 0]
    STORE R4, [R10 + 4]

sorted:
    ; Load final sorted results for verification
    LOAD R11, [R10 + 0]  ; Should be 50000
    LOAD R12, [R10 + 4]  ; Should be 100000
    LOAD R13, [R10 + 8]  ; Should be 300000
    LOAD R14, [R10 + 12] ; Should be 750000
    
    HALT
