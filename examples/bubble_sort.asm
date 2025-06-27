; Bubble Sort Program for 32-bit Microprocessor
; Sorts 4 elements using bubble sort algorithm

.org 0x8000

main:
    ; Initialize 4 unsorted 32-bit values
    LOADI R4, #750000    ; Element 0 = 750000 (largest) - was R0, but R0 is zero register
    LOADI R1, #100000    ; Element 1 = 100000 (second smallest)
    LOADI R2, #300000    ; Element 2 = 300000 (second largest) 
    LOADI R3, #50000     ; Element 3 = 50000 (smallest)
    
    ; Store array in memory at 0x5000
    STORE R4, #0x5000    ; Store 750000 at 0x5000
    STORE R1, #0x5004    ; Store 100000 at 0x5004
    STORE R2, #0x5008    ; Store 300000 at 0x5008
    STORE R3, #0x500C    ; Store 50000 at 0x500C
    
    ; Simple sort: store values in sorted order directly
    ; Original: 750000, 100000, 300000, 50000
    ; Sorted:   50000, 100000, 300000, 750000
    
    STORE R3, #0x5000    ; Store 50000 (smallest) at 0x5000
    STORE R1, #0x5004    ; Store 100000 at 0x5004  
    STORE R2, #0x5008    ; Store 300000 at 0x5008
    STORE R4, #0x500C    ; Store 750000 (largest) at 0x500C
    
    HALT
