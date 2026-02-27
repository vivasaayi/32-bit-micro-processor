; Branch & Jump Verification Test
; Tests: Branching logic, JAL, JALR (RET)

.org 0x0
    LI s0, 0x2000
    
    ; Test Unconditional Jump (Forward)
    J target_1
    J fail ; Should be skipped
    
target_1:
    ; Test BEQ (Taken)
    LI t1, 10
    LI t2, 10
    BEQ t1, t2, target_2
    J fail
    
target_2:
    ; Test BEQ (Not Taken)
    LI t1, 10
    LI t2, 20
    BEQ t1, t2, fail
    
    ; Test BNE (Taken)
    BNE t1, t2, target_3
    J fail
    
target_3:
    ; Test Function Call (JAL/RET)
    LI t5, 0
    CALL my_func
    
    ; Check side effect
    LI t6, 1
    BNE t5, t6, fail
    
    ; PASS
    LI t1, 1
    SW t1, 0(s0)
    HALT

fail:
    LI t1, 0
    SW t1, 0(s0)
    HALT

my_func:
    LI t5, 1
    RET
