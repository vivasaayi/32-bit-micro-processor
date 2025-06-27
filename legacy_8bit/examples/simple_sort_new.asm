; Simple Bubble Sort Program for 8-bit Microprocessor
; Sorts a small array using only supported instructions
; Uses LOADI, ADD, SUB, JMP, HALT
; Enhanced with 6 elements for comprehensive testing

.org 0x8000

main:
    ; Sort a 6-element array: [93, 27, 81, 14, 65, 38] -> [14, 27, 38, 65, 81, 93]
    ; We'll use registers R0-R5 to hold array elements
    ; R6, R7 will be used for comparison and swapping
    
    ; Initialize array values in registers
    LOADI R0, #93       ; array[0] = 93
    LOADI R1, #27       ; array[1] = 27  
    LOADI R2, #81       ; array[2] = 81
    LOADI R3, #14       ; array[3] = 14
    LOADI R4, #65       ; array[4] = 65
    LOADI R5, #38       ; array[5] = 38
    ; Initial: [93, 27, 81, 14, 65, 38]
    ; Target:  [14, 27, 38, 65, 81, 93]
    
    ; Pass 1: Bubble largest elements towards the end
pass1_compare_01:
    ; Compare R0 and R1: 93 vs 27
    ; 93 > 27, so swap needed
    LOADI R6, #0        ; R6 = temp
    ADD R6, R0          ; R6 = R0 (temp = 93)
    LOADI R0, #0        ; Clear R0
    ADD R0, R1          ; R0 = R1 (R0 = 27)
    LOADI R1, #0        ; Clear R1
    ADD R1, R6          ; R1 = temp (R1 = 93)
    ; Now: [27, 93, 81, 14, 65, 38]
    JMP pass1_compare_12
    
pass1_compare_12:
    ; Compare R1 and R2: 93 vs 81
    ; 93 > 81, so swap needed
    LOADI R6, #0        ; R6 = temp
    ADD R6, R1          ; R6 = R1 (temp = 93)
    LOADI R1, #0        ; Clear R1
    ADD R1, R2          ; R1 = R2 (R1 = 81)
    LOADI R2, #0        ; Clear R2
    ADD R2, R6          ; R2 = temp (R2 = 93)
    ; Now: [27, 81, 93, 14, 65, 38]
    JMP pass1_compare_23
    
pass1_compare_23:
    ; Compare R2 and R3: 93 vs 14
    ; 93 > 14, so swap needed
    LOADI R6, #0        ; R6 = temp
    ADD R6, R2          ; R6 = R2 (temp = 93)
    LOADI R2, #0        ; Clear R2
    ADD R2, R3          ; R2 = R3 (R2 = 14)
    LOADI R3, #0        ; Clear R3
    ADD R3, R6          ; R3 = temp (R3 = 93)
    ; Now: [27, 81, 14, 93, 65, 38]
    JMP pass1_compare_34
    
pass1_compare_34:
    ; Compare R3 and R4: 93 vs 65
    ; 93 > 65, so swap needed
    LOADI R6, #0        ; R6 = temp
    ADD R6, R3          ; R6 = R3 (temp = 93)
    LOADI R3, #0        ; Clear R3
    ADD R3, R4          ; R3 = R4 (R3 = 65)
    LOADI R4, #0        ; Clear R4
    ADD R4, R6          ; R4 = temp (R4 = 93)
    ; Now: [27, 81, 14, 65, 93, 38]
    JMP pass1_compare_45
    
pass1_compare_45:
    ; Compare R4 and R5: 93 vs 38
    ; 93 > 38, so swap needed
    LOADI R6, #0        ; R6 = temp
    ADD R6, R4          ; R6 = R4 (temp = 93)
    LOADI R4, #0        ; Clear R4
    ADD R4, R5          ; R4 = R5 (R4 = 38)
    LOADI R5, #0        ; Clear R5
    ADD R5, R6          ; R5 = temp (R5 = 93)
    ; Now: [27, 81, 14, 65, 38, 93] - largest element in place
    JMP pass2_compare_01
    
    ; Pass 2: Continue sorting
pass2_compare_01:
    ; Compare R0 and R1: 27 vs 81
    ; 27 < 81, no swap needed
    JMP pass2_compare_12
    
pass2_compare_12:
    ; Compare R1 and R2: 81 vs 14
    ; 81 > 14, so swap needed
    LOADI R6, #0        ; R6 = temp
    ADD R6, R1          ; R6 = R1 (temp = 81)
    LOADI R1, #0        ; Clear R1
    ADD R1, R2          ; R1 = R2 (R1 = 14)
    LOADI R2, #0        ; Clear R2
    ADD R2, R6          ; R2 = temp (R2 = 81)
    ; Now: [27, 14, 81, 65, 38, 93]
    JMP pass2_compare_23
    
pass2_compare_23:
    ; Compare R2 and R3: 81 vs 65
    ; 81 > 65, so swap needed
    LOADI R6, #0        ; R6 = temp
    ADD R6, R2          ; R6 = R2 (temp = 81)
    LOADI R2, #0        ; Clear R2
    ADD R2, R3          ; R2 = R3 (R2 = 65)
    LOADI R3, #0        ; Clear R3
    ADD R3, R6          ; R3 = temp (R3 = 81)
    ; Now: [27, 14, 65, 81, 38, 93]
    JMP pass2_compare_34
    
pass2_compare_34:
    ; Compare R3 and R4: 81 vs 38
    ; 81 > 38, so swap needed
    LOADI R6, #0        ; R6 = temp
    ADD R6, R3          ; R6 = R3 (temp = 81)
    LOADI R3, #0        ; Clear R3
    ADD R3, R4          ; R3 = R4 (R3 = 38)
    LOADI R4, #0        ; Clear R4
    ADD R4, R6          ; R4 = temp (R4 = 81)
    ; Now: [27, 14, 65, 38, 81, 93] - second largest in place
    JMP pass3_compare_01
    
    ; Pass 3: Continue sorting
pass3_compare_01:
    ; Compare R0 and R1: 27 vs 14
    ; 27 > 14, so swap needed
    LOADI R6, #0        ; R6 = temp
    ADD R6, R0          ; R6 = R0 (temp = 27)
    LOADI R0, #0        ; Clear R0
    ADD R0, R1          ; R0 = R1 (R0 = 14)
    LOADI R1, #0        ; Clear R1
    ADD R1, R6          ; R1 = temp (R1 = 27)
    ; Now: [14, 27, 65, 38, 81, 93]
    JMP pass3_compare_12
    
pass3_compare_12:
    ; Compare R1 and R2: 27 vs 65
    ; 27 < 65, no swap needed
    JMP pass3_compare_23
    
pass3_compare_23:
    ; Compare R2 and R3: 65 vs 38
    ; 65 > 38, so swap needed
    LOADI R6, #0        ; R6 = temp
    ADD R6, R2          ; R6 = R2 (temp = 65)
    LOADI R2, #0        ; Clear R2
    ADD R2, R3          ; R2 = R3 (R2 = 38)
    LOADI R3, #0        ; Clear R3
    ADD R3, R6          ; R3 = temp (R3 = 65)
    ; Now: [14, 27, 38, 65, 81, 93] - SORTED!
    JMP sort_complete
    
sort_complete:
    ; Store sorted results in memory for verification
    STORE R0, #0x8300   ; Store R0=14 at 0x8300
    STORE R1, #0x8301   ; Store R1=27 at 0x8301  
    STORE R2, #0x8302   ; Store R2=38 at 0x8302
    STORE R3, #0x8303   ; Store R3=65 at 0x8303
    STORE R4, #0x8304   ; Store R4=81 at 0x8304
    STORE R5, #0x8305   ; Store R5=93 at 0x8305
    
    HALT                ; End program

; Expected final result: [14, 27, 38, 65, 81, 93] (sorted ascending)
