; RV32M Multiplication Test
; Tests: MUL, MULH, MULHU, MULHSU operations

.org 0x0
    ; Initialize pass flag address
    LI t0, 0x2000

    ; Test MUL (lower 32 bits)
    LI t1, 0x12345678  ; 305419896
    LI t2, 0x87654321  ; 2271560481
    MUL t3, t1, t2     ; Expected: lower 32 bits of 305419896 * 2271560481
    LI t4, 0x1DF4C0C8 ; Expected result (calculated)
    BNE t3, t4, fail

    ; Test MULH (signed × signed, upper 32 bits)
    LI t1, 0x80000000  ; -2147483648 (INT_MIN)
    LI t2, 0x80000000  ; -2147483648 (INT_MIN)
    MULH t3, t1, t2    ; Expected: upper 32 bits of INT_MIN * INT_MIN
    LI t4, 0x40000000 ; Expected: 0x40000000 (positive result)
    BNE t3, t4, fail

    ; Test MULHU (unsigned × unsigned, upper 32 bits)
    LI t1, 0xFFFFFFFF  ; 4294967295 (UINT_MAX)
    LI t2, 0xFFFFFFFF  ; 4294967295 (UINT_MAX)
    MULHU t3, t1, t2   ; Expected: upper 32 bits of UINT_MAX * UINT_MAX
    LI t4, 0xFFFFFFFE ; Expected: 0xFFFFFFFE
    BNE t3, t4, fail

    ; Test MULHSU (signed × unsigned, upper 32 bits)
    LI t1, 0x80000000  ; -2147483648 (signed)
    LI t2, 0xFFFFFFFF  ; 4294967295 (unsigned)
    MULHSU t3, t1, t2  ; Expected: upper 32 bits of signed(-2^31) * unsigned(2^32-1)
    LI t4, 0xFFFFFFFF ; Expected: 0xFFFFFFFF (all 1s)
    BNE t3, t4, fail

    ; Test positive signed multiplication
    LI t1, 1000
    LI t2, 2000
    MUL t3, t1, t2     ; 1000 * 2000 = 2,000,000
    LI t4, 2000000
    BNE t3, t4, fail

    ; Test MULH with positive numbers
    LI t1, 0x10000000  ; 268435456
    LI t2, 0x10000000  ; 268435456
    MULH t3, t1, t2    ; Upper 32 bits of 268435456 * 268435456
    LI t4, 0x4         ; Expected: 0x4
    BNE t3, t4, fail

    ; PASS - All tests passed
    LI t1, 1
    SW t1, 0(t0)
    HALT

fail:
    LI t1, 0
    SW t1, 0(t0)
    HALT