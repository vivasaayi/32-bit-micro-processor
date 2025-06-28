/*
 * Minimal JVM Demo for RISC Processor
 * Uses only local variables - no globals
 */

// Execute bytecode for "5 + 3 * 2" = 11
int jvm_execute() {
    // Local JVM state
    int stack0 = 0;
    int stack1 = 0;
    int stack2 = 0;
    int stack3 = 0;
    int sp = 0;
    int pc = 0;
    
    // Execute bytecode sequence
    while (pc < 6) {
        int opcode = 0;
        
        // Get bytecode instruction (hardcoded for "5 + 3 * 2")
        if (pc == 0) opcode = 8;   // OP_ICONST_5
        if (pc == 1) opcode = 6;   // OP_ICONST_3  
        if (pc == 2) opcode = 5;   // OP_ICONST_2
        if (pc == 3) opcode = 104; // OP_IMUL
        if (pc == 4) opcode = 96;  // OP_IADD
        if (pc == 5) opcode = 177; // OP_RETURN
        
        pc = pc + 1;
        
        if (opcode == 5) {        // OP_ICONST_2
            // Push 2 onto stack
            if (sp == 0) stack0 = 2;
            if (sp == 1) stack1 = 2;
            if (sp == 2) stack2 = 2;
            if (sp == 3) stack3 = 2;
            sp = sp + 1;
        } else if (opcode == 6) { // OP_ICONST_3
            // Push 3 onto stack
            if (sp == 0) stack0 = 3;
            if (sp == 1) stack1 = 3;
            if (sp == 2) stack2 = 3;
            if (sp == 3) stack3 = 3;
            sp = sp + 1;
        } else if (opcode == 8) { // OP_ICONST_5
            // Push 5 onto stack
            if (sp == 0) stack0 = 5;
            if (sp == 1) stack1 = 5;
            if (sp == 2) stack2 = 5;
            if (sp == 3) stack3 = 5;
            sp = sp + 1;
        } else if (opcode == 96) { // OP_IADD
            // Pop two values, add them, push result
            sp = sp - 1;
            int b = 0;
            if (sp == 0) b = stack0;
            if (sp == 1) b = stack1;
            if (sp == 2) b = stack2;
            if (sp == 3) b = stack3;
            
            sp = sp - 1;
            int a = 0;
            if (sp == 0) a = stack0;
            if (sp == 1) a = stack1;
            if (sp == 2) a = stack2;
            if (sp == 3) a = stack3;
            
            int result = a + b;
            if (sp == 0) stack0 = result;
            if (sp == 1) stack1 = result;
            if (sp == 2) stack2 = result;
            if (sp == 3) stack3 = result;
            sp = sp + 1;
        } else if (opcode == 104) { // OP_IMUL
            // Pop two values, multiply them, push result
            sp = sp - 1;
            int b = 0;
            if (sp == 0) b = stack0;
            if (sp == 1) b = stack1;
            if (sp == 2) b = stack2;
            if (sp == 3) b = stack3;
            
            sp = sp - 1;
            int a = 0;
            if (sp == 0) a = stack0;
            if (sp == 1) a = stack1;
            if (sp == 2) a = stack2;
            if (sp == 3) a = stack3;
            
            int result = a * b;
            if (sp == 0) stack0 = result;
            if (sp == 1) stack1 = result;
            if (sp == 2) stack2 = result;
            if (sp == 3) stack3 = result;
            sp = sp + 1;
        } else if (opcode == 177) { // OP_RETURN
            break;
        }
    }
    
    // Return top of stack as result
    if (sp > 0) {
        sp = sp - 1;
        if (sp == 0) return stack0;
        if (sp == 1) return stack1;
        if (sp == 2) return stack2;
        if (sp == 3) return stack3;
    }
    return 0;
}

int main() {
    // Execute hardcoded Java bytecode: "5 + 3 * 2" = 11
    int result = jvm_execute();
    
    // Verify result is 11
    if (result == 11) {
        return 1;  // Success
    } else {
        return 0;  // Failure
    }
}
