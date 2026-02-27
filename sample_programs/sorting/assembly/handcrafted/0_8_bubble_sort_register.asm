; 32-bit Microprocessor Test Program: Sort 10 values using registers only
; Bubble sort, using R1-R10 for input, R11-R20 for output, R21-R31 for temp/counters

.org 0x00000000

main:
    ; Load 10 unsorted values into R1-R10
    LOADI R1, #50000
    LOADI R2, #10000
    LOADI R3, #80000
    LOADI R4, #30000
    LOADI R5, #70000
    LOADI R6, #20000
    LOADI R7, #60000
    LOADI R8, #40000
    LOADI R9, #90000
    LOADI R10, #25000

    ; Copy input to output registers R11-R20
    ADD R11, R1, R0
    ADD R12, R2, R0
    ADD R13, R3, R0
    ADD R14, R4, R0
    ADD R15, R5, R0
    ADD R16, R6, R0
    ADD R17, R7, R0
    ADD R18, R8, R0
    ADD R19, R9, R0
    ADD R20, R10, R0

    ; Bubble sort (fully unrolled for 10 elements, 9 passes)
    ; Use R21 as temp, R22 as comparison result

    ; Pass 1
    SUB R22, R11, R12
    CMP R22, R0
    JZ skip1_1
    JLT skip1_1
    ADD R21, R11, R0
    ADD R11, R12, R0
    ADD R12, R21, R0
skip1_1:
    SUB R22, R12, R13
    CMP R22, R0
    JZ skip1_2
    JLT skip1_2
    ADD R21, R12, R0
    ADD R12, R13, R0
    ADD R13, R21, R0
skip1_2:
    SUB R22, R13, R14
    CMP R22, R0
    JZ skip1_3
    JLT skip1_3
    ADD R21, R13, R0
    ADD R13, R14, R0
    ADD R14, R21, R0
skip1_3:
    SUB R22, R14, R15
    CMP R22, R0
    JZ skip1_4
    JLT skip1_4
    ADD R21, R14, R0
    ADD R14, R15, R0
    ADD R15, R21, R0
skip1_4:
    SUB R22, R15, R16
    CMP R22, R0
    JZ skip1_5
    JLT skip1_5
    ADD R21, R15, R0
    ADD R15, R16, R0
    ADD R16, R21, R0
skip1_5:
    SUB R22, R16, R17
    CMP R22, R0
    JZ skip1_6
    JLT skip1_6
    ADD R21, R16, R0
    ADD R16, R17, R0
    ADD R17, R21, R0
skip1_6:
    SUB R22, R17, R18
    CMP R22, R0
    JZ skip1_7
    JLT skip1_7
    ADD R21, R17, R0
    ADD R17, R18, R0
    ADD R18, R21, R0
skip1_7:
    SUB R22, R18, R19
    CMP R22, R0
    JZ skip1_8
    JLT skip1_8
    ADD R21, R18, R0
    ADD R18, R19, R0
    ADD R19, R21, R0
skip1_8:
    SUB R22, R19, R20
    CMP R22, R0
    JZ skip1_9
    JLT skip1_9
    ADD R21, R19, R0
    ADD R19, R20, R0
    ADD R20, R21, R0
skip1_9:

    ; Pass 2
    SUB R22, R11, R12
    CMP R22, R0
    JZ skip2_1
    JLT skip2_1
    ADD R21, R11, R0
    ADD R11, R12, R0
    ADD R12, R21, R0
skip2_1:
    SUB R22, R12, R13
    CMP R22, R0
    JZ skip2_2
    JLT skip2_2
    ADD R21, R12, R0
    ADD R12, R13, R0
    ADD R13, R21, R0
skip2_2:
    SUB R22, R13, R14
    CMP R22, R0
    JZ skip2_3
    JLT skip2_3
    ADD R21, R13, R0
    ADD R13, R14, R0
    ADD R14, R21, R0
skip2_3:
    SUB R22, R14, R15
    CMP R22, R0
    JZ skip2_4
    JLT skip2_4
    ADD R21, R14, R0
    ADD R14, R15, R0
    ADD R15, R21, R0
skip2_4:
    SUB R22, R15, R16
    CMP R22, R0
    JZ skip2_5
    JLT skip2_5
    ADD R21, R15, R0
    ADD R15, R16, R0
    ADD R16, R21, R0
skip2_5:
    SUB R22, R16, R17
    CMP R22, R0
    JZ skip2_6
    JLT skip2_6
    ADD R21, R16, R0
    ADD R16, R17, R0
    ADD R17, R21, R0
skip2_6:
    SUB R22, R17, R18
    CMP R22, R0
    JZ skip2_7
    JLT skip2_7
    ADD R21, R17, R0
    ADD R17, R18, R0
    ADD R18, R21, R0
skip2_7:
    SUB R22, R18, R19
    CMP R22, R0
    JZ skip2_8
    JLT skip2_8
    ADD R21, R18, R0
    ADD R18, R19, R0
    ADD R19, R21, R0
skip2_8:
    SUB R22, R19, R20
    CMP R22, R0
    JZ skip2_9
    JLT skip2_9
    ADD R21, R19, R0
    ADD R19, R20, R0
    ADD R20, R21, R0
skip2_9:

    ; Pass 3
    SUB R22, R11, R12
    CMP R22, R0
    JZ skip3_1
    JLT skip3_1
    ADD R21, R11, R0
    ADD R11, R12, R0
    ADD R12, R21, R0
skip3_1:
    SUB R22, R12, R13
    CMP R22, R0
    JZ skip3_2
    JLT skip3_2
    ADD R21, R12, R0
    ADD R12, R13, R0
    ADD R13, R21, R0
skip3_2:
    SUB R22, R13, R14
    CMP R22, R0
    JZ skip3_3
    JLT skip3_3
    ADD R21, R13, R0
    ADD R13, R14, R0
    ADD R14, R21, R0
skip3_3:
    SUB R22, R14, R15
    CMP R22, R0
    JZ skip3_4
    JLT skip3_4
    ADD R21, R14, R0
    ADD R14, R15, R0
    ADD R15, R21, R0
skip3_4:
    SUB R22, R15, R16
    CMP R22, R0
    JZ skip3_5
    JLT skip3_5
    ADD R21, R15, R0
    ADD R15, R16, R0
    ADD R16, R21, R0
skip3_5:
    SUB R22, R16, R17
    CMP R22, R0
    JZ skip3_6
    JLT skip3_6
    ADD R21, R16, R0
    ADD R16, R17, R0
    ADD R17, R21, R0
skip3_6:
    SUB R22, R17, R18
    CMP R22, R0
    JZ skip3_7
    JLT skip3_7
    ADD R21, R17, R0
    ADD R17, R18, R0
    ADD R18, R21, R0
skip3_7:
    SUB R22, R18, R19
    CMP R22, R0
    JZ skip3_8
    JLT skip3_8
    ADD R21, R18, R0
    ADD R18, R19, R0
    ADD R19, R21, R0
skip3_8:
    SUB R22, R19, R20
    CMP R22, R0
    JZ skip3_9
    JLT skip3_9
    ADD R21, R19, R0
    ADD R19, R20, R0
    ADD R20, R21, R0
skip3_9:

    ; Pass 4
    SUB R22, R11, R12
    CMP R22, R0
    JZ skip4_1
    JLT skip4_1
    ADD R21, R11, R0
    ADD R11, R12, R0
    ADD R12, R21, R0
skip4_1:
    SUB R22, R12, R13
    CMP R22, R0
    JZ skip4_2
    JLT skip4_2
    ADD R21, R12, R0
    ADD R12, R13, R0
    ADD R13, R21, R0
skip4_2:
    SUB R22, R13, R14
    CMP R22, R0
    JZ skip4_3
    JLT skip4_3
    ADD R21, R13, R0
    ADD R13, R14, R0
    ADD R14, R21, R0
skip4_3:
    SUB R22, R14, R15
    CMP R22, R0
    JZ skip4_4
    JLT skip4_4
    ADD R21, R14, R0
    ADD R14, R15, R0
    ADD R15, R21, R0
skip4_4:
    SUB R22, R15, R16
    CMP R22, R0
    JZ skip4_5
    JLT skip4_5
    ADD R21, R15, R0
    ADD R15, R16, R0
    ADD R16, R21, R0
skip4_5:
    SUB R22, R16, R17
    CMP R22, R0
    JZ skip4_6
    JLT skip4_6
    ADD R21, R16, R0
    ADD R16, R17, R0
    ADD R17, R21, R0
skip4_6:
    SUB R22, R17, R18
    CMP R22, R0
    JZ skip4_7
    JLT skip4_7
    ADD R21, R17, R0
    ADD R17, R18, R0
    ADD R18, R21, R0
skip4_7:
    SUB R22, R18, R19
    CMP R22, R0
    JZ skip4_8
    JLT skip4_8
    ADD R21, R18, R0
    ADD R18, R19, R0
    ADD R19, R21, R0
skip4_8:
    SUB R22, R19, R20
    CMP R22, R0
    JZ skip4_9
    JLT skip4_9
    ADD R21, R19, R0
    ADD R19, R20, R0
    ADD R20, R21, R0
skip4_9:

    ; Pass 5
    SUB R22, R11, R12
    CMP R22, R0
    JZ skip5_1
    JLT skip5_1
    ADD R21, R11, R0
    ADD R11, R12, R0
    ADD R12, R21, R0
skip5_1:
    SUB R22, R12, R13
    CMP R22, R0
    JZ skip5_2
    JLT skip5_2
    ADD R21, R12, R0
    ADD R12, R13, R0
    ADD R13, R21, R0
skip5_2:
    SUB R22, R13, R14
    CMP R22, R0
    JZ skip5_3
    JLT skip5_3
    ADD R21, R13, R0
    ADD R13, R14, R0
    ADD R14, R21, R0
skip5_3:
    SUB R22, R14, R15
    CMP R22, R0
    JZ skip5_4
    JLT skip5_4
    ADD R21, R14, R0
    ADD R14, R15, R0
    ADD R15, R21, R0
skip5_4:
    SUB R22, R15, R16
    CMP R22, R0
    JZ skip5_5
    JLT skip5_5
    ADD R21, R15, R0
    ADD R15, R16, R0
    ADD R16, R21, R0
skip5_5:
    SUB R22, R16, R17
    CMP R22, R0
    JZ skip5_6
    JLT skip5_6
    ADD R21, R16, R0
    ADD R16, R17, R0
    ADD R17, R21, R0
skip5_6:
    SUB R22, R17, R18
    CMP R22, R0
    JZ skip5_7
    JLT skip5_7
    ADD R21, R17, R0
    ADD R17, R18, R0
    ADD R18, R21, R0
skip5_7:
    SUB R22, R18, R19
    CMP R22, R0
    JZ skip5_8
    JLT skip5_8
    ADD R21, R18, R0
    ADD R18, R19, R0
    ADD R19, R21, R0
skip5_8:
    SUB R22, R19, R20
    CMP R22, R0
    JZ skip5_9
    JLT skip5_9
    ADD R21, R19, R0
    ADD R19, R20, R0
    ADD R20, R21, R0
skip5_9:

    ; Pass 6
    SUB R22, R11, R12
    CMP R22, R0
    JZ skip6_1
    JLT skip6_1
    ADD R21, R11, R0
    ADD R11, R12, R0
    ADD R12, R21, R0
skip6_1:
    SUB R22, R12, R13
    CMP R22, R0
    JZ skip6_2
    JLT skip6_2
    ADD R21, R12, R0
    ADD R12, R13, R0
    ADD R13, R21, R0
skip6_2:
    SUB R22, R13, R14
    CMP R22, R0
    JZ skip6_3
    JLT skip6_3
    ADD R21, R13, R0
    ADD R13, R14, R0
    ADD R14, R21, R0
skip6_3:
    SUB R22, R14, R15
    CMP R22, R0
    JZ skip6_4
    JLT skip6_4
    ADD R21, R14, R0
    ADD R14, R15, R0
    ADD R15, R21, R0
skip6_4:
    SUB R22, R15, R16
    CMP R22, R0
    JZ skip6_5
    JLT skip6_5
    ADD R21, R15, R0
    ADD R15, R16, R0
    ADD R16, R21, R0
skip6_5:
    SUB R22, R16, R17
    CMP R22, R0
    JZ skip6_6
    JLT skip6_6
    ADD R21, R16, R0
    ADD R16, R17, R0
    ADD R17, R21, R0
skip6_6:
    SUB R22, R17, R18
    CMP R22, R0
    JZ skip6_7
    JLT skip6_7
    ADD R21, R17, R0
    ADD R17, R18, R0
    ADD R18, R21, R0
skip6_7:
    SUB R22, R18, R19
    CMP R22, R0
    JZ skip6_8
    JLT skip6_8
    ADD R21, R18, R0
    ADD R18, R19, R0
    ADD R19, R21, R0
skip6_8:
    SUB R22, R19, R20
    CMP R22, R0
    JZ skip6_9
    JLT skip6_9
    ADD R21, R19, R0
    ADD R19, R20, R0
    ADD R20, R21, R0
skip6_9:

    ; Pass 7
    SUB R22, R11, R12
    CMP R22, R0
    JZ skip7_1
    JLT skip7_1
    ADD R21, R11, R0
    ADD R11, R12, R0
    ADD R12, R21, R0
skip7_1:
    SUB R22, R12, R13
    CMP R22, R0
    JZ skip7_2
    JLT skip7_2
    ADD R21, R12, R0
    ADD R12, R13, R0
    ADD R13, R21, R0
skip7_2:
    SUB R22, R13, R14
    CMP R22, R0
    JZ skip7_3
    JLT skip7_3
    ADD R21, R13, R0
    ADD R13, R14, R0
    ADD R14, R21, R0
skip7_3:
    SUB R22, R14, R15
    CMP R22, R0
    JZ skip7_4
    JLT skip7_4
    ADD R21, R14, R0
    ADD R14, R15, R0
    ADD R15, R21, R0
skip7_4:
    SUB R22, R15, R16
    CMP R22, R0
    JZ skip7_5
    JLT skip7_5
    ADD R21, R15, R0
    ADD R15, R16, R0
    ADD R16, R21, R0
skip7_5:
    SUB R22, R16, R17
    CMP R22, R0
    JZ skip7_6
    JLT skip7_6
    ADD R21, R16, R0
    ADD R16, R17, R0
    ADD R17, R21, R0
skip7_6:
    SUB R22, R17, R18
    CMP R22, R0
    JZ skip7_7
    JLT skip7_7
    ADD R21, R17, R0
    ADD R17, R18, R0
    ADD R18, R21, R0
skip7_7:
    SUB R22, R18, R19
    CMP R22, R0
    JZ skip7_8
    JLT skip7_8
    ADD R21, R18, R0
    ADD R18, R19, R0
    ADD R19, R21, R0
skip7_8:
    SUB R22, R19, R20
    CMP R22, R0
    JZ skip7_9
    JLT skip7_9
    ADD R21, R19, R0
    ADD R19, R20, R0
    ADD R20, R21, R0
skip7_9:

    ; Pass 8
    SUB R22, R11, R12
    CMP R22, R0
    JZ skip8_1
    JLT skip8_1
    ADD R21, R11, R0
    ADD R11, R12, R0
    ADD R12, R21, R0
skip8_1:
    SUB R22, R12, R13
    CMP R22, R0
    JZ skip8_2
    JLT skip8_2
    ADD R21, R12, R0
    ADD R12, R13, R0
    ADD R13, R21, R0
skip8_2:
    SUB R22, R13, R14
    CMP R22, R0
    JZ skip8_3
    JLT skip8_3
    ADD R21, R13, R0
    ADD R13, R14, R0
    ADD R14, R21, R0
skip8_3:
    SUB R22, R14, R15
    CMP R22, R0
    JZ skip8_4
    JLT skip8_4
    ADD R21, R14, R0
    ADD R14, R15, R0
    ADD R15, R21, R0
skip8_4:
    SUB R22, R15, R16
    CMP R22, R0
    JZ skip8_5
    JLT skip8_5
    ADD R21, R15, R0
    ADD R15, R16, R0
    ADD R16, R21, R0
skip8_5:
    SUB R22, R16, R17
    CMP R22, R0
    JZ skip8_6
    JLT skip8_6
    ADD R21, R16, R0
    ADD R16, R17, R0
    ADD R17, R21, R0
skip8_6:
    SUB R22, R17, R18
    CMP R22, R0
    JZ skip8_7
    JLT skip8_7
    ADD R21, R17, R0
    ADD R17, R18, R0
    ADD R18, R21, R0
skip8_7:
    SUB R22, R18, R19
    CMP R22, R0
    JZ skip8_8
    JLT skip8_8
    ADD R21, R18, R0
    ADD R18, R19, R0
    ADD R19, R21, R0
skip8_8:
    SUB R22, R19, R20
    CMP R22, R0
    JZ skip8_9
    JLT skip8_9
    ADD R21, R19, R0
    ADD R19, R20, R0
    ADD R20, R21, R0
skip8_9:

    ; Pass 9
    SUB R22, R11, R12
    CMP R22, R0
    JZ skip9_1
    JLT skip9_1
    ADD R21, R11, R0
    ADD R11, R12, R0
    ADD R12, R21, R0
skip9_1:
    SUB R22, R12, R13
    CMP R22, R0
    JZ skip9_2
    JLT skip9_2
    ADD R21, R12, R0
    ADD R12, R13, R0
    ADD R13, R21, R0
skip9_2:
    SUB R22, R13, R14
    CMP R22, R0
    JZ skip9_3
    JLT skip9_3
    ADD R21, R13, R0
    ADD R13, R14, R0
    ADD R14, R21, R0
skip9_3:
    SUB R22, R14, R15
    CMP R22, R0
    JZ skip9_4
    JLT skip9_4
    ADD R21, R14, R0
    ADD R14, R15, R0
    ADD R15, R21, R0
skip9_4:
    SUB R22, R15, R16
    CMP R22, R0
    JZ skip9_5
    JLT skip9_5
    ADD R21, R15, R0
    ADD R15, R16, R0
    ADD R16, R21, R0
skip9_5:
    SUB R22, R16, R17
    CMP R22, R0
    JZ skip9_6
    JLT skip9_6
    ADD R21, R16, R0
    ADD R16, R17, R0
    ADD R17, R21, R0
skip9_6:
    SUB R22, R17, R18
    CMP R22, R0
    JZ skip9_7
    JLT skip9_7
    ADD R21, R17, R0
    ADD R17, R18, R0
    ADD R18, R21, R0
skip9_7:
    SUB R22, R18, R19
    CMP R22, R0
    JZ skip9_8
    JLT skip9_8
    ADD R21, R18, R0
    ADD R18, R19, R0
    ADD R19, R21, R0
skip9_8:
    SUB R22, R19, R20
    CMP R22, R0
    JZ skip9_9
    JLT skip9_9
    ADD R21, R19, R0
    ADD R19, R20, R0
    ADD R20, R21, R0
skip9_9:

    ; Store sorted output to memory
    STORE R11, #0x1000
    STORE R12, #0x1004
    STORE R13, #0x1008
    STORE R14, #0x100C
    STORE R15, #0x1010
    STORE R16, #0x1014
    STORE R17, #0x1018
    STORE R18, #0x101C
    STORE R19, #0x1020
    STORE R20, #0x1024

    HALT
