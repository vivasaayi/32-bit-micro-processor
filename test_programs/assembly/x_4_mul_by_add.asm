; Multiply two numbers (e.g., 7 * 6) using repeated addition
; Result stored in r3

start:
    mov r1, #7       ; Multiplicand
    mov r2, #6       ; Multiplier
    mov r3, #0       ; Result accumulator

mul_loop:
    cmp r2, #0
    jz end_mul
    add r3, r3, r1   ; r3 += r1
    sub r2, r2, #1   ; r2--
    jmp mul_loop

end_mul:
    halt             ; stop execution (r3 = 42)
