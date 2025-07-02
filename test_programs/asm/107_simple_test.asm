.org 0x8000
; Write 8 colored pixels at the top-left of the framebuffer and verify each write

main:
    mov r9, #0x4000         ; Debug address (not framebuffer)
    mov r10, #0xDEADBEEF    ; Unique debug value
    store r10, [r9]
    
    mov r1, #0x800         ; Framebuffer base address (2048)

    mov r2, #0xFF000000    ; Red
    store r2, [r1]
    load r3, [r1]
    cmp r3, r2
    beq next1
    halt                   ; Halt if mismatch
next1:
    add r1, r1, #4

    mov r2, #0x00FF0000    ; Green
    store r2, [r1]
    load r3, [r1]
    cmp r3, r2
    beq next2
    halt
next2:
    mov r9, #0x4000         ; Debug address (not framebuffer)
    mov r10, #0xDEADBEEF    ; Unique debug value
    store r10, [r9]

    add r1, r1, #4

    mov r2, #0x0000FF00    ; Blue
    store r2, [r1]
    load r3, [r1]
    cmp r3, r2
    beq next3
    halt
next3:
    add r1, r1, #4

    mov r2, #0xFFFF0000    ; Yellow
    store r2, [r1]
    load r3, [r1]
    cmp r3, r2
    beq next4
    halt
next4:
    add r1, r1, #4

    mov r2, #0xFF00FF00    ; Magenta
    store r2, [r1]
    load r3, [r1]
    cmp r3, r2
    beq next5
    halt
next5:
    add r1, r1, #4

    mov r2, #0x00FFFF00    ; Cyan
    store r2, [r1]
    load r3, [r1]
    cmp r3, r2
    beq next6
    halt
next6:
    add r1, r1, #4

    mov r2, #0xFFFFFF00    ; White
    store r2, [r1]
    load r3, [r1]
    cmp r3, r2
    beq next7
    halt
next7:
    add r1, r1, #4

    mov r2, #0x80808000    ; Gray
    store r2, [r1]
    load r3, [r1]
    cmp r3, r2
    beq delay_loop
    halt

    ; Delay loop to keep the pattern visible
delay_loop:
    mov r8, #10000000
wait_loop:
    sub r8, r8, #1
    cmp r8, #0
    beq end_program
    jmp wait_loop

end_program:
    halt