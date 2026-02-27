; Simple RV32M Division Test - Direct check
; Tests basic DIV, DIVU, REM, REMU operations

.org 0x0
    ; Initialize pass flag address
    LI x5, 0x2000

    ; Test DIV: 20 / 3 = 6
    LI x6, 20
    LI x7, 3
    DIV x8, x6, x7    ; x8 = 6
    SW x8, 4(x5)      ; Store result to 0x2004

    ; Test REM: 20 % 3 = 2
    LI x6, 20
    LI x7, 3
    REM x8, x6, x7    ; x8 = 2
    SW x8, 8(x5)      ; Store result to 0x2008

    ; Test DIVU: 20 / 3 = 6
    LI x6, 20
    LI x7, 3
    DIVU x8, x6, x7   ; x8 = 6
    SW x8, 12(x5)     ; Store result to 0x200c

    ; Test REMU: 20 % 3 = 2
    LI x6, 20
    LI x7, 3
    REMU x8, x6, x7   ; x8 = 2
    SW x8, 16(x5)     ; Store result to 0x2010

    ; Test division by zero: 20 / 0 = 0xFFFFFFFF
    LI x6, 20
    LI x7, 0
    DIV x8, x6, x7    ; x8 = 0xFFFFFFFF
    SW x8, 20(x5)     ; Store result to 0x2014

    ; Test signed overflow: INT_MIN / -1 = INT_MIN
    LI x6, 0x80000000  ; INT_MIN
    LI x7, 0xFFFFFFFF  ; -1
    DIV x8, x6, x7    ; x8 = 0x80000000
    SW x8, 24(x5)     ; Store result to 0x2018

    ; If all correct: 0x2004=6, 0x2008=2, 0x200c=6, 0x2010=2, 0x2014=0xFFFFFFFF, 0x2018=0x80000000
    HALT