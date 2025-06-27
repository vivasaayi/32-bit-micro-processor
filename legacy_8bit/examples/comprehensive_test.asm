; Comprehensive test program for 8-bit microprocessor
; Tests arithmetic, logic, and system instructions

.org 0x8000

main:
    ; Test basic arithmetic
    LOADI R0, #10      ; Load 10 into R0
    LOADI R1, #5       ; Load 5 into R1
    ADD R0, R1         ; R0 = 10 + 5 = 15
    
    ; Test logic operations
    LOADI R2, #0xFF    ; Load 0xFF into R2
    LOADI R3, #0x0F    ; Load 0x0F into R3
    AND R2, R3         ; R2 = 0xFF & 0x0F = 0x0F
    
    ; Test subtraction
    LOADI R4, #20      ; Load 20 into R4
    LOADI R5, #8       ; Load 8 into R5
    SUB R4, R5         ; R4 = 20 - 8 = 12
    
    ; Test comparison and branching
    CMP R0, R1         ; Compare R0 (15) with R1 (5)
    JGE end            ; Jump if R0 >= R1 (should jump)
    
    ; This should not execute
    LOADI R6, #99      ; Should be skipped
    
end:
    LOADI R7, #42      ; Load success code
    HALT               ; Stop execution

; Expected final register values:
; R0 = 15 (0x0F)
; R1 = 5  (0x05) 
; R2 = 15 (0x0F)
; R3 = 15 (0x0F)
; R4 = 12 (0x0C)
; R5 = 8  (0x08)
; R6 = 0  (0x00) - should remain 0
; R7 = 42 (0x2A) - success code
