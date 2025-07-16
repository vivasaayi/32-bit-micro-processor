; Add values from all general-purpose registers (R1 to R31) and store the result in R30

main:
    ; Initialize registers with different values (R1 to R31)
    LOADI R1, #1
    LOADI R2, #2
    LOADI R3, #3
    LOADI R4, #4
    LOADI R5, #5
    LOADI R6, #6
    LOADI R7, #7
    LOADI R8, #8
    LOADI R9, #9
    LOADI R10, #10
    LOADI R11, #11
    LOADI R12, #12
    LOADI R13, #13
    LOADI R14, #14
    LOADI R15, #15
    LOADI R16, #16
    LOADI R17, #17
    LOADI R18, #18
    LOADI R19, #19
    LOADI R20, #20
    LOADI R21, #21
    LOADI R22, #22
    LOADI R23, #23
    LOADI R24, #24
    LOADI R25, #25
    LOADI R26, #26
    LOADI R27, #27
    LOADI R28, #28
    LOADI R29, #29
    LOADI R30, #30
    LOADI R31, #31

    ; Accumulate sum in R30 (skip R0)
    ; LOADI R30, #0
    ADD R30, R30, R1
    ADD R30, R30, R2
    ADD R30, R30, R3
    ADD R30, R30, R4
    ADD R30, R30, R5
    ADD R30, R30, R6
    ADD R30, R30, R7
    ADD R30, R30, R8
    ADD R30, R30, R9
    ADD R30, R30, R10
    ADD R30, R30, R11
    ADD R30, R30, R12
    ADD R30, R30, R13
    ADD R30, R30, R14
    ADD R30, R30, R15
    ADD R30, R30, R16
    ADD R30, R30, R17
    ADD R30, R30, R18
    ADD R30, R30, R19
    ADD R30, R30, R20
    ADD R30, R30, R21
    ADD R30, R30, R22
    ADD R30, R30, R23
    ADD R30, R30, R24
    ADD R30, R30, R25
    ADD R30, R30, R26
    ADD R30, R30, R27
    ADD R30, R30, R28
    ADD R30, R30, R29
    ;ADD R30, R30, R30
    ADD R30, R30, R31

    ; Store result for verification
    STORE R30, 0x8000   ; Store sum of 1..31 = 496
    HALT
