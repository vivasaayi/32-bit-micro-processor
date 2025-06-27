; Basic Operating System Kernel for 8-bit Microprocessor
; Demonstrates process management, system calls, and basic multitasking

; Kernel starts at 0x8000
.org 0x8000

; System call table
syscall_table:
    JMP sys_exit       ; 0x00
    JMP sys_read       ; 0x01
    JMP sys_write      ; 0x02
    JMP sys_open       ; 0x03
    JMP sys_close      ; 0x04
    JMP sys_fork       ; 0x05
    JMP sys_exec       ; 0x06
    JMP sys_wait       ; 0x07
    JMP sys_getpid     ; 0x08
    JMP sys_sleep      ; 0x09

kernel_start:
    ; Initialize kernel
    LOADI R7, #0x7F    ; Set stack pointer
    
    ; Initialize MMU
    LOADI R0, #0xE0    ; Page table base high byte
    ; MMU initialization would go here
    
    ; Initialize timer for task switching
    LOADI R0, #100     ; 10ms timer
    OUT R0, #0x15      ; Timer compare low
    LOADI R0, #0
    OUT R0, #0x16      ; Timer compare high
    LOADI R0, #0x07    ; Enable timer, continuous mode, interrupt
    OUT R0, #0x10      ; Timer control
    
    ; Enable interrupts
    EI
    
    ; Start first user process
    CALL start_init_process
    
    ; Kernel idle loop
kernel_idle:
    ; This would be the scheduler in a real OS
    HALT               ; For now, just halt
    JMP kernel_idle

; Start the init process (first user process)
start_init_process:
    ; Set up process 0 (init)
    LOADI R0, #0       ; Process ID 0
    LOADI R1, #0x1000  ; User space start
    ; Set up page table for user process
    ; Switch to user mode
    ; Jump to user code
    RET

; System call handler
syscall_handler:
    ; R0 contains syscall number
    ; R1, R2, R3 contain arguments
    
    ; Disable interrupts during system call
    DI
    
    ; Check syscall number bounds
    CMPI R0, #10
    JCS invalid_syscall
    
    ; Jump to appropriate system call
    ; This is simplified - real implementation would use a jump table
    CMPI R0, #0
    JEQ sys_exit
    CMPI R0, #1
    JEQ sys_read
    CMPI R0, #2
    JEQ sys_write
    ; ... etc
    
invalid_syscall:
    LOADI R0, #-1      ; Return error
    EI
    IRET

; System call implementations
sys_exit:
    ; Terminate current process
    ; In a real OS, this would clean up process resources
    HALT

sys_read:
    ; Read from file descriptor in R1, buffer in R2, count in R3
    ; For now, just read from UART
    IN R0, #0          ; Read from UART
    STORER R0, R2      ; Store in buffer
    LOADI R0, #1       ; Return bytes read
    EI
    IRET

sys_write:
    ; Write to file descriptor in R1, buffer in R2, count in R3
    ; For now, just write to UART
    LOADR R0, R2       ; Load from buffer
    OUT R0, #0         ; Write to UART
    LOADI R0, #1       ; Return bytes written
    EI
    IRET

sys_open:
    ; File operations not implemented in this simple example
    LOADI R0, #-1
    EI
    IRET

sys_close:
    LOADI R0, #0
    EI
    IRET

sys_fork:
    ; Process creation - very simplified
    LOADI R0, #1       ; Return child PID to parent
    EI
    IRET

sys_exec:
    ; Execute new program - not implemented
    LOADI R0, #-1
    EI
    IRET

sys_wait:
    ; Wait for child process - not implemented
    LOADI R0, #0
    EI
    IRET

sys_getpid:
    ; Return current process ID
    LOADI R0, #1       ; Simplified - always return 1
    EI
    IRET

sys_sleep:
    ; Sleep for specified time - simplified
    ; Just waste some cycles
    LOADI R1, #100
sleep_loop:
    SUBI R1, #1
    JNE sleep_loop
    LOADI R0, #0
    EI
    IRET

; Timer interrupt service routine (task scheduler)
timer_isr:
    ; Save current process state
    PUSH R0
    PUSH R1
    PUSH R2
    PUSH R3
    PUSH R4
    PUSH R5
    PUSH R6
    
    ; Simple round-robin scheduler would go here
    ; For now, just acknowledge interrupt and return
    
    ; Restore process state
    POP R6
    POP R5
    POP R4
    POP R3
    POP R2
    POP R1
    POP R0
    
    IRET

; Basic init process (runs in user space at 0x1000)
.org 0x1000
init_process:
    ; Print startup message
    LOADI R0, #2       ; sys_write
    LOADI R1, #1       ; stdout
    LOADI R2, #startup_msg
    LOADI R3, #25      ; message length
    SYSCALL #2
    
    ; Simple shell loop
shell_loop:
    ; Print prompt
    LOADI R0, #2       ; sys_write
    LOADI R1, #1       ; stdout
    LOADI R2, #prompt
    LOADI R3, #2       ; prompt length
    SYSCALL #2
    
    ; Read command
    LOADI R0, #1       ; sys_read
    LOADI R1, #0       ; stdin
    LOADI R2, #command_buffer
    LOADI R3, #64      ; buffer size
    SYSCALL #1
    
    ; For now, just echo the command
    LOADI R0, #2       ; sys_write
    LOADI R1, #1       ; stdout
    LOADI R2, #command_buffer
    LOADI R3, #1       ; echo one character
    SYSCALL #2
    
    JMP shell_loop

; Data
startup_msg:
    .db "MicroLinux 0.1 Starting...", 0x0D, 0x0A

prompt:
    .db "$ "

command_buffer:
    .db 0, 0, 0, 0, 0, 0, 0, 0  ; 64 byte buffer
    .db 0, 0, 0, 0, 0, 0, 0, 0
    .db 0, 0, 0, 0, 0, 0, 0, 0
    .db 0, 0, 0, 0, 0, 0, 0, 0
    .db 0, 0, 0, 0, 0, 0, 0, 0
    .db 0, 0, 0, 0, 0, 0, 0, 0
    .db 0, 0, 0, 0, 0, 0, 0, 0
    .db 0, 0, 0, 0, 0, 0, 0, 0

; Interrupt vectors
.org 0xFF00
    JMP kernel_start   ; Reset
    JMP timer_isr      ; Timer
    JMP syscall_handler ; System call (UART interrupt repurposed)
    JMP kernel_start   ; External
