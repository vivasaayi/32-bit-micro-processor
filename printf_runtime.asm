; printf_runtime.asm - Basic printf implementation
; Supports simple string output for your processor

printf:
    ; Input: R1 = pointer to format string
    ; For now, just implement basic string output
    PUSH R2
    PUSH R3
    
printf_loop:
    LOAD R2, [R1]        ; Load character from string
    CMP R2, #0           ; Check for null terminator
    BEQ printf_done
    
    ; Output character (assuming memory-mapped output at 0x5000)
    STORE R2, [#0x5000]
    
    ADD R1, R1, #1       ; Move to next character
    JMP printf_loop
    
printf_done:
    POP R3
    POP R2
    RET

; String output helper
puts:
    ; Input: R1 = string pointer
    CALL printf
    RET
