; Bubble Sort Real - 32-bit version
; Simple bubble sort implementation

.org 0x8000

main:
    ; Initialize array values 
    LOADI R4, #75000    ; Element 0 - was R0, but R0 is zero register
    LOADI R1, #25000    ; Element 1
    LOADI R2, #50000    ; Element 2  
    LOADI R3, #10000    ; Element 3
    
    ; Store in memory at 0x4000
    LOADI R10, #0x4000
    STORE R4, R10, #0   ; Store 75000
    STORE R1, R10, #4   ; Store 25000
    STORE R2, R10, #8   ; Store 50000
    STORE R3, R10, #12  ; Store 10000
    
    HALT
