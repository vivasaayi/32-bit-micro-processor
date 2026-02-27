.org 0x8000
; Fill the entire framebuffer with a single color (solid red), using word addressing

main:
    ; Debug marker - program started
    mov r20, #0x4000
    mov r21, #0xCAFEBABE
    store r21, [r20]
    
    ; Initialize framebuffer base address (word address)
    mov r12, #0x800      ; Framebuffer base (word address)
    mov r13, #76800      ; Total pixels (words)
    
    ; Build solid red color (0xFF000000) in r2
    mov r2, #0xFF
    add r2, r2, r2        ; 0x1FE
    add r2, r2, r2        ; 0x3FC
    add r2, r2, r2        ; 0x7F8
    add r2, r2, r2        ; 0xFF0
    add r2, r2, r2        ; 0x1FE0
    add r2, r2, r2        ; 0x3FC0
    add r2, r2, r2        ; 0x7F80
    add r2, r2, r2        ; 0xFF00
    add r2, r2, r2        ; 0x1FE00
    add r2, r2, r2        ; 0x3FC00
    add r2, r2, r2        ; 0x7F800
    add r2, r2, r2        ; 0xFF000
    add r2, r2, r2        ; 0x1FE000
    add r2, r2, r2        ; 0x3FC000
    add r2, r2, r2        ; 0x7F8000
    add r2, r2, r2        ; 0xFF0000
    add r2, r2, r2        ; 0x1FE0000
    add r2, r2, r2        ; 0x3FC0000
    add r2, r2, r2        ; 0x7F80000
    add r2, r2, r2        ; 0xFF00000
    add r2, r2, r2        ; 0x1FE00000
    add r2, r2, r2        ; 0x3FC00000
    add r2, r2, r2        ; 0x7F800000
    add r2, r2, r2        ; 0xFF000000
    
fill_loop:
    store r2, [r12]
    add r12, r12, #1      ; Next pixel (word address)
    sub r13, r13, #1      ; Pixels remaining
    cmp r13, #0
    bne fill_loop
    
    ; Debug marker - program completed
    mov r20, #0x4004
    mov r21, #0xDEADBEEF
    store r21, [r20]
    
    ; Infinite loop to keep pattern visible
infinite_loop:
    jmp infinite_loop

end_program:
    halt
