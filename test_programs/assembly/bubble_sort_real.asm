; Bubble Sort Real - 32-bit version
; Minimal, working 8-element bubble sort with direct addressing for output at 0x0200

.org 0x8000

; Initialize array in memory at 0x0100
LOADI R1, #70
STORE R1, #0x0100
LOADI R1, #18
STORE R1, #0x0104
LOADI R1, #35
STORE R1, #0x0108
LOADI R1, #73
STORE R1, #0x010C
LOADI R1, #126
STORE R1, #0x0110
LOADI R1, #142
STORE R1, #0x0114
LOADI R1, #201
STORE R1, #0x0118
LOADI R1, #239
STORE R1, #0x011C

; Bubble sort: outer loop i = 0 to 6
LOADI R11, #0      ; i = 0
LOOP_I:
    LOADI R12, #0  ; j = 0
    LOOP_J:
        LOADI R13, #7
        LOADI R16, #111
        SUB R13, R13, R11   ; 7 - i
        LOADI R16, #222
        SUBI R13, R13, 1    ; 7 - i - 1
        LOADI R16, #333
        LOADI R14, #0x0100
        LOAD R20, R14, #0
        ADDI R14, R14, 4
        LOAD R21, R14, #0
        ADDI R14, R14, 4
        LOAD R22, R14, #0
        ADDI R14, R14, 4
        LOAD R23, R14, #0
        ADDI R14, R14, 4
        LOAD R24, R14, #0
        ADDI R14, R14, 4
        LOAD R25, R14, #0
        ADDI R14, R14, 4
        LOAD R26, R14, #0
        ADDI R14, R14, 4
        LOAD R27, R14, #0
        LOADI R16, #444
        CMP R12, R13
        ; If j == 7-i-1, break
        JZ END_J
        ; If j > 7-i-1, break (repeat CMP and JZ for clarity)
        ; (If only JZ and JMP are available, this is sufficient)
        ; Copy all memory values to R20-R27 for visualization
        
        ; Calculate addresses for arr[j] and arr[j+1]
        LOADI R14, #0x0100
        SHL R15, R12, 2     ; addr = j * 4
        ADD R15, R14, R15   ; addr = base + j*4
        LOAD R16, R15, #0   ; arr[j]
        ADDI R17, R15, 4
        LOAD R18, R17, #0   ; arr[j+1]
        ; Compare arr[j] > arr[j+1]
        CMP R16, R18
        JLE SKIP_SWAP
        ; Swap arr[j] and arr[j+1]
        STORE R18, R15, #0
        STORE R16, R17, #0
    SKIP_SWAP:
        ADDI R12, R12, 1
        JMP LOOP_J
    END_J:
    ADDI R11, R11, 1
    LOADI R13, #7
    CMP R11, R13
    JLT LOOP_I

; Copy sorted array to 0x0200 using direct addressing
LOADI R12, #0
COPY_LOOP:
    LOADI R14, #0x0100
    SHL R15, R12, 2
    ADD R16, R14, R15      ; R16 = 0x0100 + i*4 (src)
    LOAD R13, R16, #0      ; R13 = value
    LOADI R14, #0x0200
    ADD R17, R14, R15      ; R17 = 0x0200 + i*4 (dst)
    STORE R13, R17, #0     ; store value
    ADDI R12, R12, 1
    LOADI R16, #8
    CMP R12, R16
    JLT COPY_LOOP

HALT
