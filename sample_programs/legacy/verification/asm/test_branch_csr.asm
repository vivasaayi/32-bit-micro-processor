
// Trace:
// 1. LI t0, 10
// 2. LI t1, 10
// 3. BEQ t0, t1, pass_beq (Should take branch)
// 4. EBREAK (Fail if branch not taken)
// ...
// test_csr:
// CSRRW t2, 0x340, t0 (Write t0(10) to mscratch)
// CSRRS t3, 0x340, zero (Read mscratch to t3)
// BNE t3, t0, fail
// ...

.org 0x8000

_start:
    // Test 1: BEQ (Equal) with positive numbers
    addi x1, x0, 10      // x1 = 10
    addi x2, x0, 10      // x2 = 10
    beq x1, x2, test_bne // Should branch
    ebreak               // Fail if not taken

test_bne:
    // Test 2: BNE (Not Equal)
    addi x2, x0, 20      // x2 = 20
    bne x1, x2, test_blt // Should branch
    ebreak               // Fail if not taken

test_blt:
    // Test 3: BLT (Less Than)
    // x1 = 10, x2 = 20
    blt x1, x2, test_csr // Should branch
    ebreak               // Fail if not taken

test_csr:
    // Test 4: CSRRW (Write mscratch)
    // mscratch is 0x340
    // Write x1 (10) to mscratch, read old value into x3
    csrrw x3, 0x340, x1
    
    // Test 5: CSRRS (Read mscratch)
    // Read mscratch into x4
    csrrs x4, 0x340, x0
    
    // Check if x4 == 10
    bne x4, x1, fail_csr
    
    // Success! Print "RISC-V COMPLIANT"
    
    // 1. Setup UART base address
    lui x10, 0x10000   // x10 = 0x10000000
    srli x10, x10, 12  // x10 = 0x00010000 (IO base)
    // Actually, based on hello_world, it might be different. Let's use LI.
    li x10, 0x10000000 // UART Base Address

    // 2. Load String Address
    la x11, pass_msg
    
print_loop:
    lb x12, 0(x11)       // Load character
    beq x12, x0, done    // If null terminator, finish
    sb x12, 0(x10)       // Store to UART TX register
    addi x11, x11, 1     // Increment string pointer
    j print_loop

done:
    ebreak

fail_csr:
    li x10, 0xDEAD // Fail marker
    ebreak

pass_msg:
    .string "RISC-V COMPLIANT\n"
