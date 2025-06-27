; Hello World Program for 8-bit Microprocessor
; Demonstrates basic I/O and string output via UART

; Program starts at kernel space
.org 0x8000

start:
    ; Initialize stack pointer
    LOADI R7, #0x7F    ; High byte of stack pointer
    
    ; Enable interrupts
    EI
    
    ; Print "Hello World!" string
    LOADI R0, #hello_msg
    CALL print_string
    
    ; Echo loop - read from UART and echo back
echo_loop:
    IN R0, #0          ; Read from UART
    CMP R0, #0         ; Check if data available
    JEQ echo_loop      ; If no data, keep waiting
    
    OUT R0, #0         ; Echo character back
    
    ; Check for ESC key to exit
    CMPI R0, #27       ; ESC character
    JEQ shutdown
    
    JMP echo_loop      ; Continue echo loop

; Print null-terminated string
; Input: R0 = pointer to string
print_string:
    PUSH R1
    PUSH R2
    
print_loop:
    LOADR R1, R0       ; Load character from string
    CMPI R1, #0        ; Check for null terminator
    JEQ print_done
    
    OUT R1, #0         ; Output character to UART
    ADDI R0, #1        ; Move to next character
    JMP print_loop
    
print_done:
    POP R2
    POP R1
    RET

; System shutdown
shutdown:
    LOADI R0, #goodbye_msg
    CALL print_string
    HALT

; Data section
hello_msg:
    .db "Hello World from 8-bit CPU!", 0x0D, 0x0A, 0x00

goodbye_msg:
    .db "Goodbye!", 0x0D, 0x0A, 0x00

; Interrupt vector table (at end of ROM)
.org 0xFF00
    JMP start          ; Reset vector
    JMP timer_isr      ; Timer interrupt
    JMP uart_isr       ; UART interrupt
    JMP external_isr   ; External interrupt

; Interrupt service routines
timer_isr:
    ; Simple timer ISR - could implement task switching here
    IRET

uart_isr:
    ; UART interrupt service routine
    IRET

external_isr:
    ; External interrupt service routine
    IRET
