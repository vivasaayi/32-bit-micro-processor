; Simple test program for 8-bit microprocessor
; Tests basic arithmetic and memory operations

start:
    LOADI R0, #42      ; Load 42 into R0
    LOADI R1, #10      ; Load 10 into R1  
    ADD R0, R1         ; R0 = R0 + R1 (52)
    LOADI R2, #1       ; Load address 0x1000 (split into parts)
    LOADI R3, #0       ; High byte first for little-endian
    HALT               ; Stop execution
