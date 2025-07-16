; Test all 32 registers: initialize to 0, then add 2 to each (except R0) in a loop, 5 times.
; R1-R30 are the data registers. R31 is the loop counter.
; R0 will always remain 0.
; After 5 loops, R1-R30 should each contain the value 10.

.org 0x8000

main:
    ; Initialize data registers R1-R30 to 0.
    ; R0 is hardwired to 0, so we can use it for initialization.
    ADD R1, R0, R0
    ADD R2, R0, R0
    ADD R3, R0, R0
    ADD R4, R0, R0
    ADD R5, R0, R0
    ADD R6, R0, R0
    ADD R7, R0, R0
    ADD R8, R0, R0
    ADD R9, R0, R0
    ADD R10, R0, R0
    ADD R11, R0, R0
    ADD R12, R0, R0
    ADD R13, R0, R0
    ADD R14, R0, R0
    ADD R15, R0, R0
    ADD R16, R0, R0
    ADD R17, R0, R0
    ADD R18, R0, R0
    ADD R19, R0, R0
    ADD R20, R0, R0
    ADD R21, R0, R0
    ADD R22, R0, R0
    ADD R23, R0, R0
    ADD R24, R0, R0
    ADD R25, R0, R0
    ADD R26, R0, R0
    ADD R27, R0, R0
    ADD R28, R0, R0
    ADD R29, R0, R0
    ADD R30, R0, R0

    ; Set up loop counter in R31
    LOADI R31, #5

loop_start:
    ; Add 2 to each register R1-R30
    ADDI R1, R1, #2
    ADDI R2, R2, #2
    ADDI R3, R3, #2
    ADDI R4, R4, #2
    ADDI R5, R5, #2
    ADDI R6, R6, #2
    ADDI R7, R7, #2
    ADDI R8, R8, #2
    ADDI R9, R9, #2
    ADDI R10, R10, #2
    ADDI R11, R11, #2
    ADDI R12, R12, #2
    ADDI R13, R13, #2
    ADDI R14, R14, #2
    ADDI R15, R15, #2
    ADDI R16, R16, #2
    ADDI R17, R17, #2
    ADDI R18, R18, #2
    ADDI R19, R19, #2
    ADDI R20, R20, #2
    ADDI R21, R21, #2
    ADDI R22, R22, #2
    ADDI R23, R23, #2
    ADDI R24, R24, #2
    ADDI R25, R25, #2
    ADDI R26, R26, #2
    ADDI R27, R27, #2
    ADDI R28, R28, #2
    ADDI R29, R29, #2
    ADDI R30, R30, #2

    ; Decrement loop counter and branch if not zero (use CMP/JZ/JMP style)
    SUBI R31, R31, #1
    CMP R31, R0
    JZ end_loop
    JMP loop_start

end_loop:
    ; Store results for verification
    ; R1-R30 should all be 10
    STORE R1, 0x8001
    STORE R2, 0x8002
    STORE R3, 0x8003
    STORE R4, 0x8004
    STORE R5, 0x8005
    STORE R6, 0x8006
    STORE R7, 0x8007
    STORE R8, 0x8008
    STORE R9, 0x8009
    STORE R10, 0x800A
    STORE R11, 0x800B
    STORE R12, 0x800C
    STORE R13, 0x800D
    STORE R14, 0x800E
    STORE R15, 0x800F
    STORE R16, 0x8010
    STORE R17, 0x8011
    STORE R18, 0x8012
    STORE R19, 0x8013
    STORE R20, 0x8014
    STORE R21, 0x8015
    STORE R22, 0x8016
    STORE R23, 0x8017
    STORE R24, 0x8018
    STORE R25, 0x8019
    STORE R26, 0x801A
    STORE R27, 0x801B
    STORE R28, 0x801C
    STORE R29, 0x801D
    STORE R30, 0x801E
    STORE R31, 0x801F  ; Store final counter value (should be 0)

    HALT
