; Simple Bubble Sort - Fixed version using only direct addressing
; This version avoids register+offset addressing and uses only supported instructions

.org 0x8000

; Initialize array in memory using direct addressing
LOADI R1, #70
STORE R1, #0x0100
LOADI R1, #18  
STORE R1, #0x0104
LOADI R1, #35
STORE R1, #0x0108
LOADI R1, #73
STORE R1, #0x010C

; Simple bubble sort for 4 elements using only direct addressing
; We'll manually unroll the loops to avoid complex addressing

; Pass 1: Compare positions 0,1 then 1,2 then 2,3
LOAD R10, #0x0100    ; element 0
LOAD R11, #0x0104    ; element 1
SUB R12, R10, R11    ; R12 = R10 - R11
CMP R12, R0          ; Correct compare for swap logic
JZ SKIP_SWAP_01      ; If equal, skip swap
JLT SKIP_SWAP_01     ; If less, skip swap
; Swap elements 0 and 1 (R10 > R11, so swap)
STORE R11, #0x0100   ; Store smaller value (R11) at position 0
STORE R10, #0x0104   ; Store larger value (R10) at position 1

LOAD R15, #0x0100    ; Render
LOAD R16, #0x0104    ; Render

SKIP_SWAP_01:

; Compare positions 1,2
LOAD R10, #0x0104    ; element 1  
LOAD R11, #0x0108    ; element 2
SUB R12, R10, R11
CMP R12, R0
JZ SKIP_SWAP_12
JLT SKIP_SWAP_12
; Swap elements 1 and 2
STORE R11, #0x0104
STORE R10, #0x0108
SKIP_SWAP_12:

; Compare positions 2,3
LOAD R10, #0x0108    ; element 2
LOAD R11, #0x010C    ; element 3  
SUB R12, R10, R11
CMP R12, R0
JZ SKIP_SWAP_23
JLT SKIP_SWAP_23
; Swap elements 2 and 3
STORE R11, #0x0108
STORE R10, #0x010C
SKIP_SWAP_23:

; Pass 2: Another complete pass
LOAD R10, #0x0100
LOAD R11, #0x0104
SUB R12, R10, R11
CMP R12, R0
JZ SKIP_SWAP2_01
JLT SKIP_SWAP2_01
STORE R11, #0x0100
STORE R10, #0x0104
SKIP_SWAP2_01:

LOAD R10, #0x0104
LOAD R11, #0x0108
SUB R12, R10, R11
CMP R12, R0
JZ SKIP_SWAP2_12
JLT SKIP_SWAP2_12
STORE R11, #0x0104
STORE R10, #0x0108
SKIP_SWAP2_12:

LOAD R10, #0x0108
LOAD R11, #0x010C
SUB R12, R10, R11
CMP R12, R0
JZ SKIP_SWAP2_23
JLT SKIP_SWAP2_23
STORE R11, #0x0108
STORE R10, #0x010C
SKIP_SWAP2_23:

; Pass 3: Final pass
LOAD R10, #0x0100
LOAD R11, #0x0104
SUB R12, R10, R11
CMP R12, R0
JZ SKIP_SWAP3_01
JLT SKIP_SWAP3_01
STORE R11, #0x0100
STORE R10, #0x0104
SKIP_SWAP3_01:

LOAD R10, #0x0104
LOAD R11, #0x0108
SUB R12, R10, R11
CMP R12, R0
JZ SKIP_SWAP3_12
JLT SKIP_SWAP3_12
STORE R11, #0x0104
STORE R10, #0x0108
SKIP_SWAP3_12:

; Compare positions 2,3 in Pass 3
LOAD R10, #0x0108
LOAD R11, #0x010C
SUB R12, R10, R11
CMP R12, R0
JZ SKIP_SWAP3_23
JLT SKIP_SWAP3_23
STORE R11, #0x0108
STORE R10, #0x010C
SKIP_SWAP3_23:

; Load final sorted values into registers for easy viewing
LOAD R20, #0x0100
LOAD R21, #0x0104
LOAD R22, #0x0108
LOAD R23, #0x010C

HALT
