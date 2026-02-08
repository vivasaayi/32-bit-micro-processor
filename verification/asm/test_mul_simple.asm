; Simple RV32M Multiplication Test
; Tests basic MUL operation with known values

.org 0x0
    ; Initialize pass flag address
    LI t0, 0x2000

    ; Test MUL with small numbers
    LI t1, 10
    LI t2, 20
    MUL t3, t1, t2     ; 10 * 20 = 200
    LI t4, 200
    BNE t3, t4, fail

    ; Test MUL with larger numbers
    LI t1, 1000
    LI t2, 2000
    MUL t3, t1, t2     ; 1000 * 2000 = 2,000,000
    LI t4, 2000000
    BNE t3, t4, fail

    ; Test MULH with negative numbers
    LI t1, 0xFFFFFFFF  ; -1 (signed)
    LI t2, 0xFFFFFFFF  ; -1 (signed)
    MULH t3, t1, t2    ; (-1) * (-1) = 1, upper bits should be 0
    LI t4, 0
    BNE t3, t4, fail

    ; PASS - All tests passed
    LI t1, 1
    SW t1, 0(t0)
    HALT

fail:
    LI t1, 0
    SW t1, 0(t0)
    HALT