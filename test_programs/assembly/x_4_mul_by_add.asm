; Multiply two numbers (e.g., 7 * 6) using repeated addition
; Result stored in R3

main:
    ; Initialize registers
    LOADI R1, #7        ; R1 = 7 (multiplicand)
    LOADI R2, #6        ; R2 = 6 (multiplier)
    LOADI R3, #0        ; R3 = 0 (result accumulator)

mul_loop:
    ; Check if multiplier is zero
    CMP R2, #0
    JZ end_mul
    ADD R3, R3, R1      ; R3 += R1
    SUBI R2, R2, #1     ; R2--
    JMP mul_loop

end_mul:
    ; Store result for verification
    STORE R3, 0x7000    ; Store result (should be 42)
    HALT
