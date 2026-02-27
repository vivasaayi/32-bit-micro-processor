; Hello World for AruviX on QEMU
; Optimized for QEMU 'virt' machine (RAM base 0x80000000)

.org 0x80000000
_start:
    ; UART0 MMIO address in QEMU 'virt' machine
    LI t0, 0x10000000
    
    ; Load address of the string
    LA t1, msg
    
print_loop:
    LB t2, 0(t1)        ; Load byte from string
    BEQ t2, zero, end   ; If null terminator, exit
    SB t2, 0(t0)        ; Write byte to UART
    ADDI t1, t1, 1      ; Move to next character
    J print_loop        ; Repeat

end:
    LI t2, 0x0A         ; Print final newline
    SB t2, 0(t0)
    EBREAK              ; Exit QEMU

msg:
    .string "Hello from AruviX on QEMU! The loop is working perfectly."
