.org 0x8000

; Initialize stack pointer
LOADI R30, #0x000F0000
; Initialize heap pointer  
LOADI R29, #0x20000

; Function: main
main:
LOADI R1, #5
LOADI R1, #3
LOADI R1, #0
LOADI R2, #0
ADD R1, R1, R2
LOADI R0, #0
HALT
HALT
HALT

