.org 0x8000
; 108_bouncing_rectangle.asm - Animated bouncing rectangle
; Creates a rectangle that moves across the screen and bounces off edges

main:
    ; Debug marker - program started
    mov r21, #0xCAFEBABE
    mov r20, #0x5000
    store r21, [r20]
    
    ; Initialize rectangle parameters
    mov r1, #50          ; rect_x (starting X position)
    mov r2, #30          ; rect_y (starting Y position)
    mov r3, #20          ; rect_width
    mov r4, #15          ; rect_height
    mov r5, #2           ; velocity_x (pixels per frame)
    mov r6, #1           ; velocity_y (pixels per frame)
    
    ; Screen bounds
    mov r7, #320         ; screen_width
    mov r8, #240         ; screen_height
    
    mov r9, #128
    add r9, r9, r9    ; 256
    add r9, r9, r9    ; 512
    add r9, r9, r9    ; 1024
    add r9, r9, r9    ; 2048 (0x800) framebuffer base
    
    mov r10, #10000
    mov r14, #7
    mov r15, r10
add_76k_loop:
    add r10, r10, r15
    sub r14, r14, #1
    cmp r14, #0
    bne add_76k_loop
    mov r14, #6800
    add r10, r10, r14
    
    mov r11, #0xFF       ; background color (0x000000FF)
    
animation_loop:
    ; Clear the entire screen first
    mov r12, r9          ; framebuffer base
    mov r14, r10         ; total pixels
clear_loop:
    store r11, [r12]
    add r12, r12, #4
    sub r14, r14, #1
    cmp r14, #0
    bne clear_loop
    
    ; Draw the rectangle at current position
    mov r16, r2          ; current_y = rect_y
    mov r15, r4          ; rows_left = rect_height

draw_rows:
    ; Calculate start address for this row: fb_base + (current_y * 320 + rect_x) * 4
    mov r17, r16         ; current_y
    mov r18, #320
    mul r17, r17, r18    ; current_y * 320
    add r17, r17, r1     ; + rect_x
    mov r18, #4
    mul r17, r17, r18    ; * 4 (bytes per pixel)
    add r17, r17, r9     ; + framebuffer base
    
    ; Draw pixels in this row
    mov r18, r3          ; pixels_left = rect_width
    mov r13, #0xFF           ; r13 = 0x000000FF
    add r13, r13, r13        ; r13 = 0x000001FE
    add r13, r13, r13        ; r13 = 0x000003FC
    add r13, r13, r13        ; r13 = 0x000007F8
    add r13, r13, r13        ; r13 = 0x00000FF0
    add r13, r13, r13        ; r13 = 0x00001FE0
    add r13, r13, r13        ; r13 = 0x00003FC0
    add r13, r13, r13        ; r13 = 0x00007F80
    add r13, r13, r13        ; r13 = 0x0000FF00
    add r13, r13, r13        ; r13 = 0x0001FE00
    add r13, r13, r13        ; r13 = 0x0003FC00
    add r13, r13, r13        ; r13 = 0x0007F800
    add r13, r13, r13        ; r13 = 0x000FF000
    add r13, r13, r13        ; r13 = 0x001FE000
    add r13, r13, r13        ; r13 = 0x003FC000
    add r13, r13, r13        ; r13 = 0x007F8000
    add r13, r13, r13        ; r13 = 0x00FF0000
    add r13, r13, r13        ; r13 = 0x01FE0000
    add r13, r13, r13        ; r13 = 0x03FC0000
    add r13, r13, r13        ; r13 = 0x07F80000
    add r13, r13, r13        ; r13 = 0x0FF00000
    add r13, r13, r13        ; r13 = 0x1FE00000
    add r13, r13, r13        ; r13 = 0x3FC00000
    add r13, r13, r13        ; r13 = 0x7F800000
    add r13, r13, r13        ; r13 = 0xFF000000
    mov r19, #0xFF           ; r19 = 0x000000FF
    add r13, r13, r19        ; r13 = 0xFF0000FF (red)

draw_pixels:
    store r13, [r17]
    add r17, r17, #4     ; next pixel
    sub r18, r18, #1
    cmp r18, #0
    bne draw_pixels
    
    ; Next row
    add r16, r16, #1     ; current_y++
    sub r15, r15, #1     ; rows_left--
    cmp r15, #0
    bne draw_rows
    
    ; Update position
    add r1, r1, r5       ; rect_x += velocity_x
    add r2, r2, r6       ; rect_y += velocity_y
    
    ; Check X bounds and bounce
    cmp r1, #0           ; if rect_x < 0
    beq not_less_x
    jmp bounce_left
not_less_x:
    add r19, r1, r3      ; rect_x + rect_width
    cmp r19, r7          ; if (rect_x + width) >= screen_width
    beq bounce_right      ; if equal, branch
    jmp check_y_bounds    ; if less, skip bounce_right
bounce_right:
    sub r1, r7, r3       ; rect_x = screen_width - rect_width
    sub r5, r0, r5       ; velocity_x = -velocity_x (flip sign)
    jmp check_y_bounds

bounce_left:
    mov r1, #0           ; rect_x = 0
    sub r5, r0, r5       ; velocity_x = -velocity_x (flip sign)
    
check_y_bounds:
    cmp r2, #0           ; if rect_y < 0
    beq not_less_y
    jmp bounce_top
not_less_y:
    add r19, r2, r4      ; rect_y + rect_height
    cmp r19, r8          ; if (rect_y + height) >= screen_height
    beq bounce_bottom
    jmp frame_delay
bounce_bottom:
    sub r2, r8, r4       ; rect_y = screen_height - rect_height
    sub r6, r0, r6       ; velocity_y = -velocity_y (flip sign)
    jmp frame_delay

bounce_top:
    mov r2, #0           ; rect_y = 0
    sub r6, r0, r6       ; velocity_y = -velocity_y (flip sign)
    
frame_delay:
    mov r22, #100      ; r22 = 100
    mov r17, #100      ; r17 = 100 (was r18)
    mul r22, r22, r17  ; r22 = 10,000
    mov r17, #9        ; loop counter (was r18)
    mov r19, r22       ; r19 = 10,000 (constant)
delay_add_loop:
    add r22, r22, r19  ; r22 += 10,000
    sub r17, r17, #1   ; (was r18)
    cmp r17, #0        ; (was r18)
    bne delay_add_loop ; repeat 9 times, r22 = 100,000
    
    ; Debug marker - frame completed
    mov r20, #0x5004
    add r21, r21, #1     ; increment frame counter
    store r21, [r20]
    
    ; Continue animation (infinite loop)
    jmp animation_loop

end_program:
    halt
