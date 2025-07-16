; Test all 32 registers: initialize to 0, then add 2 to each (except R0) in a loop, 5 times
; R0 will always remain 0

start:
    ; Initialize all registers R1-R31 to 0
    mov r1, #0
    mov r2, #0
    mov r3, #0
    mov r4, #0
    mov r5, #0
    mov r6, #0
    mov r7, #0
    mov r8, #0
    mov r9, #0
    mov r10, #0
    mov r11, #0
    mov r12, #0
    mov r13, #0
    mov r14, #0
    mov r15, #0
    mov r16, #0
    mov r17, #0
    mov r18, #0
    mov r19, #0
    mov r20, #0
    mov r21, #0
    mov r22, #0
    mov r23, #0
    mov r24, #0
    mov r25, #0
    mov r26, #0
    mov r27, #0
    mov r28, #0
    mov r29, #0
    mov r30, #0
    mov r31, #0

    mov r20, #5      ; Loop counter (r20)
    mov r21, #2      ; Value to add (r21)

loop_all_regs:
    add r1, r1, r21
    add r2, r2, r21
    add r3, r3, r21
    add r4, r4, r21
    add r5, r5, r21
    add r6, r6, r21
    add r7, r7, r21
    add r8, r8, r21
    add r9, r9, r21
    add r10, r10, r21
    add r11, r11, r21
    add r12, r12, r21
    add r13, r13, r21
    add r14, r14, r21
    add r15, r15, r21
    add r16, r16, r21
    add r17, r17, r21
    add r18, r18, r21
    add r19, r19, r21
    add r22, r22, r21
    add r23, r23, r21
    add r24, r24, r21
    add r25, r25, r21
    add r26, r26, r21
    add r27, r27, r21
    add r28, r28, r21
    add r29, r29, r21
    add r30, r30, r21
    add r31, r31, r21

    sub r20, r20, #1
    cmp r20, #0
    jnz loop_all_regs

    halt
