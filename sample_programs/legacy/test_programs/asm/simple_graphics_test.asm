; Simple graphics test - write directly to framebuffer memory
; This test manually writes pixel data to test the framebuffer dumping

main:
    ; Write a few pixels directly to framebuffer memory at 0x800
    ; Pixel format: RRGGBB00 (RGB + alpha/padding)
    
    ; Write red pixel at position 0
    mov r1, #0x800       ; Framebuffer base address (2048)
    mov r2, #0xFF000000  ; Red pixel
    store r2, [r1]
    
    ; Write green pixel at position 1
    add r1, r1, #4
    mov r2, #0x00FF0000  ; Green pixel  
    store r2, [r1]
    
    ; Write blue pixel at position 2
    add r1, r1, #4
    mov r2, #0x0000FF00  ; Blue pixel
    store r2, [r1]
    
    ; Write yellow pixel at position 3
    add r1, r1, #4
    mov r2, #0xFFFF0000  ; Yellow pixel
    store r2, [r1]
    
    ; End program
    halt
