; Bubble Sort Program for 8-bit Microprocessor
; Sorts an array of 8-bit numbers in ascending order
; Tests memory operations, loops, and conditional logic
; Enhanced with 8 elements for comprehensive testing

.org 0x8000

main:
    ; Initialize array pointer and size
    LOADI R0, #array_start    ; R0 = pointer to array start (low byte)
    LOADI R1, #0x80          ; R1 = pointer to array start (high byte = 0x80)
    LOADI R2, #12            ; R2 = array size (12 elements - significantly increased)
    LOADI R3, #0             ; R3 = outer loop counter
    
outer_loop:
    ; Check if outer loop is done (R3 >= R2-1)
    LOADI R4, #11            ; R4 = array_size - 1 = 11 (updated for 12 elements)
    SUB R4, R3               ; R4 = (array_size-1) - outer_counter
    JZ sort_complete         ; if R4 == 0, sorting is complete
    
    ; Initialize inner loop
    LOADI R5, #0             ; R5 = inner loop counter
    
inner_loop:
    ; Check if inner loop is done (R5 >= R2-R3-1)
    LOADI R6, #11            ; R6 = array_size - 1 = 11 (updated for 12 elements)
    SUB R6, R3               ; R6 = array_size - 1 - outer_counter
    SUB R6, R5               ; R6 = array_size - 1 - outer_counter - inner_counter
    JZ inner_done            ; if R6 == 0, inner loop is done
    
    ; Load current element (array[R5])
    ; Calculate address: base + R5
    ADD R0, R5               ; R0 = base + offset
    LOAD R6, [R0]            ; R6 = array[R5]
    SUB R0, R5               ; restore R0 to base address
    
    ; Load next element (array[R5+1])
    LOADI R7, #1             ; R7 = 1
    ADD R5, R7               ; R5 = R5 + 1
    ADD R0, R5               ; R0 = base + (R5+1)
    LOAD R7, [R0]            ; R7 = array[R5+1]
    SUB R0, R5               ; restore R0 to base address
    SUB R5, #1               ; restore R5
    
    ; Compare elements (R6 vs R7)
    SUB R6, R7               ; R6 = array[R5] - array[R5+1]
    JLE no_swap              ; if array[R5] <= array[R5+1], no swap needed
    
    ; Swap elements
    ; Store array[R5+1] in temp location
    ADD R0, R5               ; R0 = base + R5
    STORE [temp], R7         ; temp = array[R5+1]
    
    ; array[R5] = array[R5+1]
    STORE [R0], R7           ; array[R5] = array[R5+1]
    
    ; array[R5+1] = temp
    LOADI R7, #1
    ADD R0, R7               ; R0 = base + R5 + 1
    LOAD R7, [temp]          ; R7 = temp
    STORE [R0], R7           ; array[R5+1] = temp
    
    ; Restore base pointer
    SUB R0, R5
    SUB R0, #1
    
no_swap:
    ; Increment inner loop counter
    LOADI R7, #1
    ADD R5, R7               ; R5++
    JMP inner_loop
    
inner_done:
    ; Increment outer loop counter
    LOADI R7, #1
    ADD R3, R7               ; R3++
    JMP outer_loop
    
sort_complete:
    ; Output sorted array
    LOADI R5, #0             ; R5 = index counter
    
output_loop:
    ; Check if output is done
    SUB R2, R5               ; R2 - R5
    JZ program_end           ; if R5 >= array_size, done
    ADD R2, R5               ; restore R2
    
    ; Load and output current element
    ADD R0, R5               ; R0 = base + index
    LOAD R6, [R0]            ; R6 = array[index]
    SUB R0, R5               ; restore R0
    
    OUT R6                   ; Output current element
    
    ; Increment index
    LOADI R7, #1
    ADD R5, R7               ; R5++
    JMP output_loop
    
program_end:
    HALT                     ; End program

; Data section - Enhanced with 12 diverse elements including edge cases
.org 0x8100
array_start:
    .byte 255   ; array[0] = 255 (maximum 8-bit value)
    .byte 1     ; array[1] = 1 (near minimum)
    .byte 128   ; array[2] = 128 (middle value)
    .byte 0     ; array[3] = 0 (minimum value)
    .byte 199   ; array[4] = 199 (large value)
    .byte 42    ; array[5] = 42 (medium value)
    .byte 17    ; array[6] = 17 (small value)
    .byte 234   ; array[7] = 234 (very large)
    .byte 73    ; array[8] = 73 (medium)
    .byte 5     ; array[9] = 5 (very small)
    .byte 156   ; array[10] = 156 (large)
    .byte 89    ; array[11] = 89 (medium-large)
    ; Expected sorted: [0, 1, 5, 17, 42, 73, 89, 128, 156, 199, 234, 255]

.org 0x8110
temp:
    .byte 0     ; Temporary storage for swapping
