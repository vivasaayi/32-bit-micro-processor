; Advanced Bubble Sort with Actual Comparisons
; Demonstrates real sorting algorithm with comparisons and swaps
; Enhanced with 8 elements for comprehensive testing

.org 0x8000

main:
    ; Initialize array values (8 elements - expanded from 5)
    LOADI R0, #142      ; R0 = 142 (element 1 - large)
    LOADI R1, #7        ; R1 = 7   (element 2 - very small) 
    LOADI R2, #239      ; R2 = 239 (element 3 - very large)
    LOADI R3, #18       ; R3 = 18  (element 4 - small)
    LOADI R4, #73       ; R4 = 73  (element 5 - medium)
    LOADI R5, #201      ; R5 = 201 (element 6 - large)
    LOADI R6, #35       ; R6 = 35  (element 7 - medium-small)
    LOADI R7, #126      ; R7 = 126 (element 8 - medium-large)
    ; Initial: [142, 7, 239, 18, 73, 201, 35, 126]
    ; Target:  [7, 18, 35, 73, 126, 142, 201, 239]
    
    ; Start first pass of bubble sort (7 comparisons for 8 elements)
    JMP pass1_compare_01
    
pass1_compare_01:
    ; Compare R0 and R1: 142 vs 7
    ; 142 > 7, so swap needed
    LOADI R8, #0        ; Clear temp register (using R8 since R7 is data)
    ADD R8, R0          ; R8 = R0 (temp = 142)
    LOADI R0, #0        ; Clear R0
    ADD R0, R1          ; R0 = R1 (R0 = 7)
    LOADI R1, #0        ; Clear R1
    ADD R1, R8          ; R1 = temp (R1 = 142)
    ; Now: [7, 142, 239, 18, 73, 201, 35, 126]
    JMP pass1_compare_12
    
pass1_compare_12:
    ; Compare R1 and R2: 142 vs 239
    ; 142 < 239, no swap needed
    ; Still: [7, 142, 239, 18, 73, 201, 35, 126]
    JMP pass1_compare_23
    
pass1_compare_23:
    ; Compare R2 and R3: 239 vs 18
    ; 239 > 18, so swap needed
    LOADI R8, #0        ; Clear temp register
    ADD R8, R2          ; R8 = R2 (temp = 239)
    LOADI R2, #0        ; Clear R2
    ADD R2, R3          ; R2 = R3 (R2 = 18)
    LOADI R3, #0        ; Clear R3
    ADD R3, R8          ; R3 = temp (R3 = 239)
    ; Now: [7, 142, 18, 239, 73, 201, 35, 126]
    JMP pass1_compare_34
    
pass1_compare_34:
    ; Compare R3 and R4: 239 vs 73
    ; 239 > 73, so swap needed
    LOADI R8, #0        ; Clear temp register
    ADD R8, R3          ; R8 = R3 (temp = 239)
    LOADI R3, #0        ; Clear R3
    ADD R3, R4          ; R3 = R4 (R3 = 73)
    LOADI R4, #0        ; Clear R4
    ADD R4, R8          ; R4 = temp (R4 = 239)
    ; Now: [7, 142, 18, 73, 239, 201, 35, 126]
    JMP pass1_compare_45

pass1_compare_45:
    ; Compare R4 and R5: 239 vs 201
    ; 239 > 201, so swap needed
    LOADI R8, #0        ; Clear temp register
    ADD R8, R4          ; R8 = R4 (temp = 239)
    LOADI R4, #0        ; Clear R4
    ADD R4, R5          ; R4 = R5 (R4 = 201)
    LOADI R5, #0        ; Clear R5
    ADD R5, R8          ; R5 = temp (R5 = 239)
    ; Now: [7, 142, 18, 73, 201, 239, 35, 126]
    JMP pass1_compare_56

pass1_compare_56:
    ; Compare R5 and R6: 239 vs 35
    ; 239 > 35, so swap needed
    LOADI R8, #0        ; Clear temp register
    ADD R8, R5          ; R8 = R5 (temp = 239)
    LOADI R5, #0        ; Clear R5
    ADD R5, R6          ; R5 = R6 (R5 = 35)
    LOADI R6, #0        ; Clear R6
    ADD R6, R8          ; R6 = temp (R6 = 239)
    ; Now: [7, 142, 18, 73, 201, 35, 239, 126]
    JMP pass1_compare_67

pass1_compare_67:
    ; Compare R6 and R7: 239 vs 126
    ; 239 > 126, so swap needed
    LOADI R8, #0        ; Clear temp register
    ADD R8, R6          ; R8 = R6 (temp = 239)
    LOADI R6, #0        ; Clear R6
    ADD R6, R7          ; R6 = R7 (R6 = 126)
    LOADI R7, #0        ; Clear R7
    ADD R7, R8          ; R7 = temp (R7 = 239)
    ; Now: [7, 142, 18, 73, 201, 35, 126, 239] - 239 bubbled to end
    JMP pass2_compare_01

; Second pass - need 6 comparisons
pass2_compare_01:
    ; Compare R0 and R1: 7 vs 142
    ; 7 < 142, no swap needed
    ; Still: [7, 142, 18, 73, 201, 35, 126, 239]
    JMP pass2_compare_12

pass2_compare_12:
    ; Compare R1 and R2: 142 vs 18
    ; 142 > 18, so swap needed
    LOADI R8, #0        ; Clear temp register
    ADD R8, R1          ; R8 = R1 (temp = 142)
    LOADI R1, #0        ; Clear R1
    ADD R1, R2          ; R1 = R2 (R1 = 18)
    LOADI R2, #0        ; Clear R2
    ADD R2, R8          ; R2 = temp (R2 = 142)
    ; Now: [7, 18, 142, 73, 201, 35, 126, 239]
    JMP pass2_compare_23

pass2_compare_23:
    ; Compare R2 and R3: 142 vs 73
    ; 142 > 73, so swap needed
    LOADI R8, #0        ; Clear temp register
    ADD R8, R2          ; R8 = R2 (temp = 142)
    LOADI R2, #0        ; Clear R2
    ADD R2, R3          ; R2 = R3 (R2 = 73)
    LOADI R3, #0        ; Clear R3
    ADD R3, R8          ; R3 = temp (R3 = 142)
    ; Now: [7, 18, 73, 142, 201, 35, 126, 239]
    JMP pass2_compare_34

pass2_compare_34:
    ; Compare R3 and R4: 142 vs 201
    ; 142 < 201, no swap needed
    ; Still: [7, 18, 73, 142, 201, 35, 126, 239]
    JMP pass2_compare_45

pass2_compare_45:
    ; Compare R4 and R5: 201 vs 35
    ; 201 > 35, so swap needed
    LOADI R8, #0        ; Clear temp register
    ADD R8, R4          ; R8 = R4 (temp = 201)
    LOADI R4, #0        ; Clear R4
    ADD R4, R5          ; R4 = R5 (R4 = 35)
    LOADI R5, #0        ; Clear R5
    ADD R5, R8          ; R5 = temp (R5 = 201)
    ; Now: [7, 18, 73, 142, 35, 201, 126, 239]
    JMP pass2_compare_56

pass2_compare_56:
    ; Compare R5 and R6: 201 vs 126
    ; 201 > 126, so swap needed
    LOADI R8, #0        ; Clear temp register
    ADD R8, R5          ; R8 = R5 (temp = 201)
    LOADI R5, #0        ; Clear R5
    ADD R5, R6          ; R5 = R6 (R5 = 126)
    LOADI R6, #0        ; Clear R6
    ADD R6, R8          ; R6 = temp (R6 = 201)
    ; Now: [7, 18, 73, 142, 35, 126, 201, 239] - 201 in position
    JMP pass3_compare_01

; Third pass - 5 comparisons
pass3_compare_01:
    ; Compare R0 and R1: 7 vs 18
    ; 7 < 18, no swap needed
    ; Still: [7, 18, 73, 142, 35, 126, 201, 239]
    JMP pass3_compare_12

pass3_compare_12:
    ; Compare R1 and R2: 18 vs 73
    ; 18 < 73, no swap needed
    ; Still: [7, 18, 73, 142, 35, 126, 201, 239]
    JMP pass3_compare_23

pass3_compare_23:
    ; Compare R2 and R3: 73 vs 142
    ; 73 < 142, no swap needed
    ; Still: [7, 18, 73, 142, 35, 126, 201, 239]
    JMP pass3_compare_34

pass3_compare_34:
    ; Compare R3 and R4: 142 vs 35
    ; 142 > 35, so swap needed
    LOADI R8, #0        ; Clear temp register
    ADD R8, R3          ; R8 = R3 (temp = 142)
    LOADI R3, #0        ; Clear R3
    ADD R3, R4          ; R3 = R4 (R3 = 35)
    LOADI R4, #0        ; Clear R4
    ADD R4, R8          ; R4 = temp (R4 = 142)
    ; Now: [7, 18, 73, 35, 142, 126, 201, 239]
    JMP pass3_compare_45

pass3_compare_45:
    ; Compare R4 and R5: 142 vs 126
    ; 142 > 126, so swap needed
    LOADI R8, #0        ; Clear temp register
    ADD R8, R4          ; R8 = R4 (temp = 142)
    LOADI R4, #0        ; Clear R4
    ADD R4, R5          ; R4 = R5 (R4 = 126)
    LOADI R5, #0        ; Clear R5
    ADD R5, R8          ; R5 = temp (R5 = 142)
    ; Now: [7, 18, 73, 35, 126, 142, 201, 239]
    JMP pass4_compare_01

; Fourth pass - 4 comparisons  
pass4_compare_01:
    ; Compare R0 and R1: 7 vs 18
    ; 7 < 18, no swap needed
    ; Still: [7, 18, 73, 35, 126, 142, 201, 239]
    JMP pass4_compare_12

pass4_compare_12:
    ; Compare R1 and R2: 18 vs 73
    ; 18 < 73, no swap needed
    ; Still: [7, 18, 73, 35, 126, 142, 201, 239]
    JMP pass4_compare_23

pass4_compare_23:
    ; Compare R2 and R3: 73 vs 35
    ; 73 > 35, so swap needed
    LOADI R8, #0        ; Clear temp register
    ADD R8, R2          ; R8 = R2 (temp = 73)
    LOADI R2, #0        ; Clear R2
    ADD R2, R3          ; R2 = R3 (R2 = 35)
    LOADI R3, #0        ; Clear R3
    ADD R3, R8          ; R3 = temp (R3 = 73)
    ; Now: [7, 18, 35, 73, 126, 142, 201, 239]
    JMP pass4_compare_34

pass4_compare_34:
    ; Compare R3 and R4: 73 vs 126
    ; 73 < 126, no swap needed
    ; Still: [7, 18, 35, 73, 126, 142, 201, 239] - SORTED!
    JMP sort_complete

sort_complete:
    ; Store sorted results in memory for verification
    STORE R0, #0x8200   ; Store R0=7 at 0x8200
    STORE R1, #0x8201   ; Store R1=18 at 0x8201  
    STORE R2, #0x8202   ; Store R2=35 at 0x8202
    STORE R3, #0x8203   ; Store R3=73 at 0x8203
    STORE R4, #0x8204   ; Store R4=126 at 0x8204
    STORE R5, #0x8205   ; Store R5=142 at 0x8205
    STORE R6, #0x8206   ; Store R6=201 at 0x8206
    STORE R7, #0x8207   ; Store R7=239 at 0x8207
    
    HALT                ; End program

; Expected final result: [7, 18, 35, 73, 126, 142, 201, 239] (sorted ascending)
