; Final RISC-V compatibility test
.org 0x0

; Test ABI register names
LI sp, 0x1000    ; Stack pointer
LI ra, 0x2000    ; Return address
LI a0, 42        ; Argument 0
LI a1, 24        ; Argument 1

; Test RV32I arithmetic
ADD t0, a0, a1   ; t0 = 42 + 24 = 66
SUB t1, a0, a1   ; t1 = 42 - 24 = 18
AND t2, t0, t1   ; t2 = 66 & 18 = 2
OR t3, t0, t1    ; t3 = 66 | 18 = 82
XOR t4, t0, t1   ; t4 = 66 ^ 18 = 80

; Test shifts
SLL t5, a0, a1   ; t5 = 42 << 24 (lower 5 bits = 24&31 = 24) = 42 << 24
SRL t6, t5, a1   ; t6 = (42 << 24) >> 24 = 42

; Test memory operations
SW t0, 0(sp)     ; Store 66 at 0x1000
SW t1, 4(sp)     ; Store 18 at 0x1004
LW s0, 0(sp)     ; Load 66
LW s1, 4(sp)     ; Load 18

; Test branches
BEQ s0, t0, branch_ok  ; Should branch
LI gp, 999      ; Should be skipped
branch_ok:
LI gp, 123      ; Should execute

; Test RV32M operations
MUL s2, a0, a1  ; s2 = 42 * 24 = 1008
DIV s3, s2, a0  ; s3 = 1008 / 42 = 24
REM s4, s2, a0  ; s4 = 1008 % 42 = 0

; Store results
SW s2, 8(sp)    ; 1008
SW s3, 12(sp)   ; 24
SW s4, 16(sp)   ; 0

; Test system instructions
ECALL           ; Environment call
EBREAK          ; Breakpoint

HALT