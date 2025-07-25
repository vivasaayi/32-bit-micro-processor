; Generated by Simple C Compiler
; Custom RISC Assembly Output

    ; Runtime support functions
malloc:
    ; Simple malloc - returns fixed heap addresses
    load r1, heap_ptr
    add r2, r1, r0
    store r2, heap_ptr
    mov r0, r1
    ret

putchar:
    ; Output character in r0
    out r0
    ret

strlen:
    ; String length - string pointer in r0
    mov r1, r0
    mov r0, #0
strlen_loop:
    load r2, [r1]
    cmp r2, #0
    je strlen_end
    add r0, r0, #1
    add r1, r1, #1
    jmp strlen_loop
strlen_end:
    ret

; Data section
heap_ptr: .word 0x10000

    ; Compound statement
    ; Function declaration
main:
    push fp
    mov fp, sp
    sub sp, sp, #64
    ; Compound statement
    ; Variable declaration
; Variable a allocated
    mov r1, #5
    ; Store initializer value for a
    ; Variable declaration
; Variable b allocated
    mov r1, #3
    ; Store initializer value for b
    ; Variable declaration
; Variable result allocated
    ; Undefined symbol
    mov r1, #0
    ; Undefined symbol
    mov r2, #0
    add r1, r1, r2
    ; Store initializer value for result
    ; Return statement
    ; Undefined symbol
    mov r0, #0
    add sp, sp, #64
    pop fp
    ret 
main_end:
    add sp, sp, #64
    pop fp
    ret 


; Program entry point
_start:
    call main
    halt
