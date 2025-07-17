; 108_bouncing_rectangle_fixed.asm - Animated bouncing rectangle
; Fixed to use working instruction set from bubble sort
; Creates a rectangle that moves across the screen and bounces off edges

.org 0x8000

main:
    ; Debug marker - program started
    LOADI R21, #0xCAFE
    LOADI R20, #0x5000
    STORE R21, [R20]

    LOAD R31, [R21]
    
    ; Initialize rectangle parameters
    LOADI R1, #50        ; rect_x (starting X position)
    LOADI R2, #30        ; rect_y (starting Y position)
    LOADI R3, #20        ; rect_width
    LOADI R4, #15        ; rect_height
    LOADI R5, #2         ; velocity_x (pixels per frame)
    LOADI R6, #1         ; velocity_y (pixels per frame)
    
    ; Screen bounds
    LOADI R7, #320       ; screen_width
    LOADI R8, #240       ; screen_height
    
    ; Calculate framebuffer base (0x000 = 0)
    LOADI R9, #0         ; framebuffer base address
    
    ; Calculate total pixels (320 * 240 = 76800)
    LOADI R10, #10000
    LOADI R14, #7
    LOADI R15, #10000
add_76k_loop:
    ADD R10, R10, R15
    SUBI R14, R14, 1
    CMP R14, R0
    JZ add_76k_done
    JMP add_76k_loop
add_76k_done:
    LOADI R14, #6800
    ADD R10, R10, R14    ; R10 = 76800 total pixels
    
    LOADI R11, #0xFF     ; background color (blue)
    
animation_loop:
    ; Clear the entire screen first
    LOADI R12, #0
    ADD R12, R12, R9     ; framebuffer base
    LOADI R14, #0
    ADD R14, R14, R10    ; total pixels
clear_loop:
    STORE R11, R12
    ADDI R12, R12, 4
    SUBI R14, R14, 1
    CMP R14, R0
    JZ clear_done
    JMP clear_loop
clear_done:
    
    ; Draw the rectangle at current position
    LOADI R16, #0
    ADD R16, R16, R2     ; current_y = rect_y
    LOADI R15, #0
    ADD R15, R15, R4     ; rows_left = rect_height

draw_rows:
    ; Calculate start address for this row: fb_base + (current_y * 320 + rect_x) * 4
    LOADI R17, #0
    ADD R17, R17, R16    ; current_y
    LOADI R18, #320
    ; Multiply by 320 using shifts and adds (320 = 256 + 64)
    LOADI R19, #0
    ADD R19, R19, R17    ; temp = current_y
    ADD R19, R19, R19    ; temp *= 2
    ADD R19, R19, R19    ; temp *= 4
    ADD R19, R19, R19    ; temp *= 8
    ADD R19, R19, R19    ; temp *= 16
    ADD R19, R19, R19    ; temp *= 32
    ADD R19, R19, R19    ; temp *= 64
    LOADI R18, #0
    ADD R18, R18, R19    ; R18 = current_y * 64
    ADD R19, R19, R19    ; temp *= 128
    ADD R19, R19, R19    ; temp *= 256
    ADD R18, R18, R19    ; R18 = current_y * 320
    
    ADD R18, R18, R1     ; + rect_x
    ADD R18, R18, R18    ; * 2
    ADD R18, R18, R18    ; * 4 (bytes per pixel)
    ADD R18, R18, R9     ; + framebuffer base
    
    ; Draw pixels in this row
    LOADI R19, #0
    ADD R19, R19, R3     ; pixels_left = rect_width
    
    ; Create red color (0xFF0000FF)
    LOADI R13, #0xFF     ; Start with 0xFF
    ADD R13, R13, R13    ; 0x1FE
    ADD R13, R13, R13    ; 0x3FC
    ADD R13, R13, R13    ; 0x7F8
    ADD R13, R13, R13    ; 0xFF0
    ADD R13, R13, R13    ; 0x1FE0
    ADD R13, R13, R13    ; 0x3FC0
    ADD R13, R13, R13    ; 0x7F80
    ADD R13, R13, R13    ; 0xFF00
    ADD R13, R13, R13    ; 0x1FE00
    ADD R13, R13, R13    ; 0x3FC00
    ADD R13, R13, R13    ; 0x7F800
    ADD R13, R13, R13    ; 0xFF000
    ADD R13, R13, R13    ; 0x1FE000
    ADD R13, R13, R13    ; 0x3FC000
    ADD R13, R13, R13    ; 0x7F8000
    ADD R13, R13, R13    ; 0xFF0000
    LOADI R20, #0xFF
    ADD R13, R13, R20    ; 0xFF00FF (red + alpha)

draw_pixels:
    STORE R13, R18
    ADDI R18, R18, 4     ; next pixel
    SUBI R19, R19, 1
    CMP R19, R0
    JZ draw_pixels_done
    JMP draw_pixels
draw_pixels_done:
    
    ; Next row
    ADDI R16, R16, 1     ; current_y++
    SUBI R15, R15, 1     ; rows_left--
    CMP R15, R0
    JZ draw_rows_done
    JMP draw_rows
draw_rows_done:
    
    ; Update position
    ADD R1, R1, R5       ; rect_x += velocity_x
    ADD R2, R2, R6       ; rect_y += velocity_y
    
    ; Check X bounds and bounce
    CMP R1, R0           ; if rect_x < 0
    JLT bounce_left
    
    ADD R19, R1, R3      ; rect_x + rect_width
    SUB R20, R19, R7     ; (rect_x + width) - screen_width
    CMP R20, R0          ; if (rect_x + width) >= screen_width
    JZ bounce_right
    JLT check_y_bounds
    
bounce_right:
    SUB R1, R7, R3       ; rect_x = screen_width - rect_width
    SUB R5, R0, R5       ; velocity_x = -velocity_x (flip sign)
    JMP check_y_bounds

bounce_left:
    LOADI R1, #0         ; rect_x = 0
    SUB R5, R0, R5       ; velocity_x = -velocity_x (flip sign)
    
check_y_bounds:
    CMP R2, R0           ; if rect_y < 0
    JLT bounce_top
    
    ADD R19, R2, R4      ; rect_y + rect_height
    SUB R20, R19, R8     ; (rect_y + height) - screen_height
    CMP R20, R0          ; if (rect_y + height) >= screen_height
    JZ bounce_bottom
    JLT frame_delay
    
bounce_bottom:
    SUB R2, R8, R4       ; rect_y = screen_height - rect_height
    SUB R6, R0, R6       ; velocity_y = -velocity_y (flip sign)
    JMP frame_delay

bounce_top:
    LOADI R2, #0         ; rect_y = 0
    SUB R6, R0, R6       ; velocity_y = -velocity_y (flip sign)
    
frame_delay:
    ; Simple delay loop
    LOADI R22, #1000
delay_loop:
    SUBI R22, R22, 1
    CMP R22, R0
    JZ delay_done
    JMP delay_loop
delay_done:
    
    ; Debug marker - frame completed
    LOADI R20, #0x5004
    ADDI R21, R21, 1     ; increment frame counter
    STORE R21, R20
    
    ; Continue animation (infinite loop)
    JMP animation_loop

end_program:
    HALT
