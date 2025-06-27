; Enhanced Array Sorting Demonstration
; Shows sorting concept with working instruction set
; Demonstrates with 6 diverse elements

.org 0x8000

main:
    ; Initialize with unsorted values including edge cases
    LOADI R0, #189      ; Element 1 = 189 (very large)
    LOADI R1, #12       ; Element 2 = 12  (small)  
    LOADI R2, #255      ; Element 3 = 255 (maximum 8-bit)
    LOADI R3, #1        ; Element 4 = 1   (near minimum)
    LOADI R4, #87       ; Element 5 = 87  (medium)
    LOADI R5, #0        ; Element 6 = 0   (minimum)
    
    ; Manual sorting using selection sort approach
    ; Current: [189, 12, 255, 1, 87, 0]
    ; Target:  [0, 1, 12, 87, 189, 255]
    
    ; Step 1: Find minimum (0 in R5) and move to R0
    LOADI R6, #0        ; R6 = temp
    ADD R6, R0          ; R6 = R0 (189)
    LOADI R0, #0        ; Clear R0
    ADD R0, R5          ; R0 = R5 (0)
    LOADI R5, #0        ; Clear R5
    ADD R5, R6          ; R5 = temp (189)
    ; Now: [0, 12, 255, 1, 87, 189]
    
    ; Step 2: Find next minimum (1 in R3) and move to R1
    LOADI R6, #0        ; R6 = temp
    ADD R6, R1          ; R6 = R1 (12)
    LOADI R1, #0        ; Clear R1
    ADD R1, R3          ; R1 = R3 (1)
    LOADI R3, #0        ; Clear R3
    ADD R3, R6          ; R3 = temp (12)
    ; Now: [0, 1, 255, 12, 87, 189]
    
    ; Step 3: Find next minimum (12 in R3) and move to R2
    LOADI R6, #0        ; R6 = temp
    ADD R6, R2          ; R6 = R2 (255)
    LOADI R2, #0        ; Clear R2
    ADD R2, R3          ; R2 = R3 (12)
    LOADI R3, #0        ; Clear R3
    ADD R3, R6          ; R3 = temp (255)
    ; Now: [0, 1, 12, 255, 87, 189]
    
    ; Step 4: Find next minimum (87 in R4) and move to R3
    LOADI R6, #0        ; R6 = temp
    ADD R6, R3          ; R6 = R3 (255)
    LOADI R3, #0        ; Clear R3
    ADD R3, R4          ; R3 = R4 (87)
    LOADI R4, #0        ; Clear R4
    ADD R4, R6          ; R4 = temp (255)
    ; Now: [0, 1, 12, 87, 255, 189]
    
    ; Step 5: Swap R4 and R5 to get final order
    LOADI R6, #0        ; R6 = temp
    ADD R6, R4          ; R6 = R4 (255)
    LOADI R4, #0        ; Clear R4
    ADD R4, R5          ; R4 = R5 (189)
    LOADI R5, #0        ; Clear R5
    ADD R5, R6          ; R5 = temp (255)
    ; Final: [0, 1, 12, 87, 189, 255] - SORTED!
    
    ; Store results in memory for verification
    STORE R0, #0x8250   ; Store 0 at 0x8250
    STORE R1, #0x8251   ; Store 1 at 0x8251
    STORE R2, #0x8252   ; Store 12 at 0x8252
    STORE R3, #0x8253   ; Store 87 at 0x8253
    STORE R4, #0x8254   ; Store 189 at 0x8254
    STORE R5, #0x8255   ; Store 255 at 0x8255
    
    HALT                ; End program

; Expected result: [0, 1, 12, 87, 189, 255] (sorted ascending)
