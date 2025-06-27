; Simple Test Program for 32-bit Microprocessor
; Tests basic arithmetic operations and memory access

.org 0x8000

main:
    ; Load immediate values
    LOADI R0, #42000    ; R0 = 42000
    LOADI R1, #10000    ; R1 = 10000
    
    ; Basic arithmetic
    ADD R2, R0, R1      ; R2 = R0 + R1 = 52000
    SUB R3, R0, R1      ; R3 = R0 - R1 = 32000
    
    ; Test memory operations
    STORE R2, #0x2000   ; Store R2 (52000) at address 0x2000
    LOAD R5, #0x2000    ; Load back from memory into R5
    
    ; Additional test values
    LOADI R4, #1000     ; R4 = 1000
    SUB R6, R2, R4      ; R6 = 52000 - 1000 = 51000
    
    ; Halt the processor
    HALT
