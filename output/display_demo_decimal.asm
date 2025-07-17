; Display Demo for Custom RISC Processor
.org 0x8000

; Initialize stack pointer
LOADI R30, #0x000F0000

main:
; Set text mode by writing 0 to 0xFF000000
LOADI R1, #1044266240
LOADI R2, #0
STORE R2, R1, #0

; Write "HELLO" to text buffer at 0xFF001000
LOADI R3, #1044267008

; Write 'H' with white on black (0x0F48)
LOADI R4, #3912
STORE R4, R3, #0

; Write 'E' (0x0F45)
LOADI R4, #3909
STORE R4, R3, #2

; Write 'L' (0x0F4C)
LOADI R4, #3916
STORE R4, R3, #4

; Write 'L' (0x0F4C)
LOADI R4, #3916
STORE R4, R3, #6

; Write 'O' (0x0F4F)
LOADI R4, #3919
STORE R4, R3, #8

; Switch to graphics mode
LOADI R2, #1
STORE R2, R1, #0

; Keep running
main_loop:
JMP main_loop

HALT
