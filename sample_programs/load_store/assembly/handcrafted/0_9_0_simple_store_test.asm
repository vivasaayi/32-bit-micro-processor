; Simple test for STORE immediate addressing

.org 0x8000

LOADI R1, #42
STORE R1, #0x0100
LOADI R2, #99 
STORE R2, #0x0104

LOAD R4, #0x0100
LOAD R5, #0x0104
HALT
