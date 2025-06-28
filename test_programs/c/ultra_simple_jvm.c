/*
 * Ultra-Simple JVM for RISC Processor
 * Demonstrates Java bytecode execution using basic C constructs only
 */

// Global variables for JVM state (simplified approach)
int jvm_stack[64];      // Operand stack
int jvm_sp;             // Stack pointer
int jvm_locals[16];     // Local variables
int jvm_pc;             // Program counter

// Initialize JVM
void jvm_init() {
    jvm_sp = 0;
    jvm_pc = 0;
    
    // Clear locals
    int i = 0;
    while (i < 16) {
        jvm_locals[i] = 0;
        i = i + 1;
    }
}

// Push value onto operand stack
void jvm_push(int value) {
    jvm_stack[jvm_sp] = value;
    jvm_sp = jvm_sp + 1;
}

// Pop value from operand stack
int jvm_pop() {
    jvm_sp = jvm_sp - 1;
    return jvm_stack[jvm_sp];
}

// Execute bytecode
int jvm_execute(int bytecode[], int length) {
    jvm_init();
    
    while (jvm_pc < length) {
        int opcode = bytecode[jvm_pc];
        jvm_pc = jvm_pc + 1;
        
        if (opcode == 3) {        // OP_ICONST_0
            jvm_push(0);
        } else if (opcode == 4) { // OP_ICONST_1
            jvm_push(1);
        } else if (opcode == 5) { // OP_ICONST_2
            jvm_push(2);
        } else if (opcode == 6) { // OP_ICONST_3
            jvm_push(3);
        } else if (opcode == 7) { // OP_ICONST_4
            jvm_push(4);
        } else if (opcode == 8) { // OP_ICONST_5
            jvm_push(5);
        } else if (opcode == 16) { // OP_BIPUSH
            int value = bytecode[jvm_pc];
            jvm_pc = jvm_pc + 1;
            jvm_push(value);
        } else if (opcode == 26) { // OP_ILOAD_0
            jvm_push(jvm_locals[0]);
        } else if (opcode == 27) { // OP_ILOAD_1
            jvm_push(jvm_locals[1]);
        } else if (opcode == 28) { // OP_ILOAD_2
            jvm_push(jvm_locals[2]);
        } else if (opcode == 29) { // OP_ILOAD_3
            jvm_push(jvm_locals[3]);
        } else if (opcode == 59) { // OP_ISTORE_0
            jvm_locals[0] = jvm_pop();
        } else if (opcode == 60) { // OP_ISTORE_1
            jvm_locals[1] = jvm_pop();
        } else if (opcode == 61) { // OP_ISTORE_2
            jvm_locals[2] = jvm_pop();
        } else if (opcode == 62) { // OP_ISTORE_3
            jvm_locals[3] = jvm_pop();
        } else if (opcode == 96) { // OP_IADD
            int b = jvm_pop();
            int a = jvm_pop();
            jvm_push(a + b);
        } else if (opcode == 100) { // OP_ISUB
            int b = jvm_pop();
            int a = jvm_pop();
            jvm_push(a - b);
        } else if (opcode == 104) { // OP_IMUL
            int b = jvm_pop();
            int a = jvm_pop();
            jvm_push(a * b);
        } else if (opcode == 108) { // OP_IDIV
            int b = jvm_pop();
            int a = jvm_pop();
            jvm_push(a / b);
        } else if (opcode == 112) { // OP_IREM (modulo)
            int b = jvm_pop();
            int a = jvm_pop();
            jvm_push(a % b);  // Uses our new MOD instruction!
        } else if (opcode == 177) { // OP_RETURN
            break;
        } else if (opcode == 255) { // OP_HALT
            break;
        }
    }
    
    // Return top of stack as result
    if (jvm_sp > 0) {
        return jvm_pop();
    } else {
        return 0;
    }
}

int main() {
    // Test program: simple Java bytecode for "5 + 3 * 2"
    // Expected result: 5 + (3 * 2) = 5 + 6 = 11
    
    int test_program[6];
    test_program[0] = 8;   // OP_ICONST_5: Push 5
    test_program[1] = 6;   // OP_ICONST_3: Push 3  
    test_program[2] = 5;   // OP_ICONST_2: Push 2
    test_program[3] = 104; // OP_IMUL: 3 * 2 = 6 (stack: [5, 6])
    test_program[4] = 96;  // OP_IADD: 5 + 6 = 11 (stack: [11])
    test_program[5] = 177; // OP_RETURN: Return result (11)
    
    int result = jvm_execute(test_program, 6);
    
    // Verify result is 11
    if (result == 11) {
        return 1;  // Success
    } else {
        return 0;  // Failure
    }
}
