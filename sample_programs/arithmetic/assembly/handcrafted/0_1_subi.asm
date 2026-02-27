; Test SUBI (Subtract Immediate) Instruction
; This program tests subtracting immediate values from registers

main:
    ; Test basic SUBI operations
    LOADI R1, #20       ; R1 = 20
    SUBI R2, R1, #5     ; R2 = R1 - 5 = 15
    SUBI R3, R2, #10    ; R3 = R2 - 10 = 5
    SUBI R4, R1, #0     ; R4 = R1 - 0 = 20 (no change)
    
    ; Test with negative immediate (double negative = addition)
    SUBI R5, R1, #-3    ; R5 = R1 - (-3) = 20 + 3 = 23
    
    ; Test edge cases
    LOADI R6, #10       ; R6 = 10
    SUBI R7, R6, #10    ; R7 = 0 (should set zero flag)
    SUBI R8, R6, #15    ; R8 = -5 (negative result, should set negative flag)
    
    ; Test with maximum immediate values
    LOADI R9, #300      ; R9 = 300
    SUBI R10, R9, #255  ; R10 = 300 - 255 = 45
    SUBI R11, R9, #-256 ; R11 = 300 - (-256) = 556
    
    ; Chain SUBI operations
    LOADI R12, #100     ; R12 = 100
    SUBI R12, R12, #10  ; R12 = 90
    SUBI R12, R12, #20  ; R12 = 70
    SUBI R12, R12, #30  ; R12 = 40
    
    ; Mixed ADDI and SUBI operations
    LOADI R13, #50      ; R13 = 50
    ADDI R13, R13, #25  ; R13 = 75
    SUBI R13, R13, #15  ; R13 = 60
    ADDI R13, R13, #5   ; R13 = 65
    SUBI R13, R13, #20  ; R13 = 45
    
    ; Store results to memory for verification
    STORE R2, 0x5000    ; Store 15
    STORE R3, 0x5004    ; Store 5
    STORE R5, 0x5008    ; Store 23
    STORE R7, 0x500C    ; Store 0
    STORE R8, 0x5010    ; Store -5
    STORE R12, 0x5014   ; Store 40
    STORE R13, 0x5018   ; Store 45
    
    HALT
