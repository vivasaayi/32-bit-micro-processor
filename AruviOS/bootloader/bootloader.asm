; =============================================================================
; AruviOS Bootloader
; =============================================================================
; Uses BIOS LBA extended reads (int 0x13 AH=0x42) to load the kernel.
; Loads the kernel in two chunks:
;   Part 1: sectors 1-127  -> 0x10000 (seg 0x1000)
;   Part 2: sectors 128-220 -> 0x20000 (seg 0x2000)
; Then in 32-bit protected mode, copies both chunks to 0x100000 and
; transitions to 64-bit long mode to execute the kernel.
; =============================================================================

[BITS 16]
[ORG 0x7C00]

KERNEL_DST      equ 0x100000
KERNEL_SECTORS  equ 221
PART1_SECS      equ 127
PART2_SECS      equ (KERNEL_SECTORS - PART1_SECS)
STACK_TOP       equ 0x90000

start:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00
    sti

    mov [boot_drive], dl

    mov si, msg_banner
    call print16

    ; Enable A20 (fast method)
    in al, 0x92
    or al, 0x02
    and al, 0xFE
    out 0x92, al

    ; --- Load Part 1: LBA 1, 127 sectors -> 0x10000 ---
    mov word [dap + 2], PART1_SECS
    mov word [dap + 4], 0x0000          ; offset
    mov word [dap + 6], 0x1000          ; segment
    mov dword [dap + 8], 1              ; LBA low
    mov dword [dap + 12], 0             ; LBA high
    mov ah, 0x42
    mov dl, [boot_drive]
    mov si, dap
    int 0x13
    jc disk_error

    ; --- Load Part 2: LBA 128, 94 sectors -> 0x20000 ---
    mov word [dap + 2], PART2_SECS
    mov word [dap + 4], 0x0000          ; offset
    mov word [dap + 6], 0x2000          ; segment
    mov dword [dap + 8], (PART1_SECS + 1)
    mov dword [dap + 12], 0
    mov ah, 0x42
    mov dl, [boot_drive]
    mov si, dap
    int 0x13
    jc disk_error

    mov si, msg_ok
    call print16

    lgdt [gdt_desc]
    mov eax, cr0
    or eax, 0x1
    mov cr0, eax
    jmp 0x08:pm32

disk_error:
    mov si, msg_err
    call print16
    jmp $

print16:
    mov ah, 0x0E
.lp: lodsb
    test al, al
    jz .done
    int 0x10
    jmp .lp
.done: ret

boot_drive  db 0x80
msg_banner  db 'AruviOS...', 13, 10, 0
msg_ok      db 'OK', 13, 10, 0
msg_err     db 'ERR', 13, 10, 0

; Disk Address Packet (16 bytes)
align 4
dap:
    db 0x10, 0x00   ; size, reserved
    dw 0            ; sector count
    dw 0            ; buffer offset
    dw 0            ; buffer segment
    dd 0            ; LBA low 32
    dd 0            ; LBA high 32

; GDT
align 8
gdt_start:
    dq 0
    dw 0xFFFF, 0x0000, 0x9A00, 0x00CF   ; 0x08: 32-bit code
    dw 0xFFFF, 0x0000, 0x9200, 0x00CF   ; 0x10: 32-bit data
    dw 0xFFFF, 0x0000, 0x9A00, 0x0020   ; 0x18: 64-bit code
    dw 0xFFFF, 0x0000, 0x9200, 0x00CF   ; 0x20: 64-bit data
gdt_end:
gdt_desc:
    dw gdt_end - gdt_start - 1
    dd gdt_start

; =============================================================================
[BITS 32]
pm32:
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov esp, STACK_TOP

    ; Copy part 1: 0x10000 -> 0x100000
    mov esi, 0x10000
    mov edi, KERNEL_DST
    mov ecx, (PART1_SECS * 512) / 4
    rep movsd

    ; Copy part 2: 0x20000 -> 0x100000 + part1_size
    mov esi, 0x20000
    mov edi, KERNEL_DST + (PART1_SECS * 512)
    mov ecx, (PART2_SECS * 512) / 4
    rep movsd

    ; Page tables: PML4@0x1000, PDPT@0x2000, PD@0x3000 (zeroed first)
    xor eax, eax
    mov edi, 0x1000
    mov ecx, 0xC00 / 4          ; 3KB = 3 tables * 1 entry each (we zero 3KB)
    rep stosd

    mov dword [0x1000], 0x2003  ; PML4[0] -> PDPT
    mov dword [0x2000], 0x3003  ; PDPT[0] -> PD
    mov dword [0x3000], 0x83    ; PD[0] -> 2MB @ 0x0 (PS|W|P)

    ; Enable PAE
    mov eax, cr4
    or eax, 1 << 5
    mov cr4, eax

    ; Load CR3 with PML4
    mov eax, 0x1000
    mov cr3, eax

    ; Set EFER.LME
    mov ecx, 0xC0000080
    rdmsr
    or eax, 1 << 8
    wrmsr

    ; Enable paging
    mov eax, cr0
    or eax, 1 << 31
    mov cr0, eax

    jmp 0x18:lm64

; =============================================================================
[BITS 64]
lm64:
    mov ax, 0x20
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov rsp, STACK_TOP

    mov eax, KERNEL_DST
    jmp rax

; =============================================================================
times 510 - ($ - $$) db 0
dw 0xAA55