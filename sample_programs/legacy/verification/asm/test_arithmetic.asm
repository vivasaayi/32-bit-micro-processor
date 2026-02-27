; Comprehensive Arithmetic Instructions Test
.org 0x0

; Setup test values
LI x1, 100       ; rs1 = 100
LI x2, 25        ; rs2 = 25
LI x10, 0x2000   ; Base address for results

; Basic arithmetic
ADD x3, x1, x2   ; x3 = 100 + 25 = 125
SW x3, 0(x10)

ADDI x4, x1, 50  ; x4 = 100 + 50 = 150
SW x4, 4(x10)

NEG x5, x2       ; x5 = -25 = 0xFFFFFFE7
SW x5, 8(x10)

SUB x6, x1, x2   ; x6 = 100 - 25 = 75
SW x6, 12(x10)

; Multiplication operations
MUL x7, x1, x2   ; x7 = 100 * 25 = 2500
SW x7, 16(x10)

MULH x8, x1, x2  ; x8 = (100 * 25)[63:32] = 0 (positive * positive)
SW x8, 20(x10)

LI x11, -50      ; Negative value for MULHSU test
MULHSU x9, x11, x2 ; x9 = (-50 * 25)[63:32] (signed * unsigned)
SW x9, 24(x10)

MULHU x12, x1, x2 ; x12 = (100 * 25)[63:32] unsigned = 0
SW x12, 28(x10)

; Division operations
DIV x13, x1, x2  ; x13 = 100 / 25 = 4
SW x13, 32(x10)

REM x14, x1, x2  ; x14 = 100 % 25 = 0
SW x14, 36(x10)

; Test with different values
LI x15, 37
LI x16, 7

DIV x17, x15, x16 ; x17 = 37 / 7 = 5
SW x17, 40(x10)

REM x18, x15, x16 ; x18 = 37 % 7 = 2
SW x18, 44(x10)

; Expected results at addresses:
; 0x2000: 125 (ADD)
; 0x2004: 150 (ADDI)
; 0x2008: 0xFFFFFFE7 (NEG -25)
; 0x200C: 75 (SUB)
; 0x2010: 2500 (MUL)
; 0x2014: 0 (MULH)
; 0x2018: upper bits of -50*25 (MULHSU)
; 0x201C: 0 (MULHU)
; 0x2020: 4 (DIV)
; 0x2024: 0 (REM)
; 0x2028: 5 (DIV 37/7)
; 0x202C: 2 (REM 37%7)

HALT