/*
 * JVM Interpreter for SimpleTest.compute
 * Generated from Java bytecode
 */

// Hardcoded bytecode for SimpleTest.compute
int bytecode[] = {16, 11, 172};
int bytecode_size = 3;

// JVM state using individual variables (compatible with our C compiler)
int jvm_stack0;
int jvm_stack1;
int jvm_stack2;
int jvm_stack3;
int jvm_sp;
int jvm_local0;
int jvm_local1;
int jvm_local2;
int jvm_local3;
int jvm_pc;

// Initialize JVM
void jvm_init() {
    jvm_sp = 0;
    jvm_pc = 0;
    jvm_stack0 = 0;
    jvm_stack1 = 0;
    jvm_stack2 = 0;
    jvm_stack3 = 0;
    jvm_local0 = 0;
    jvm_local1 = 0;
    jvm_local2 = 0;
    jvm_local3 = 0;
}

// Push value onto operand stack
void jvm_push(int value) {
    if (jvm_sp == 0) {
        jvm_stack0 = value;
    } else if (jvm_sp == 1) {
        jvm_stack1 = value;
    } else if (jvm_sp == 2) {
        jvm_stack2 = value;
    } else if (jvm_sp == 3) {
        jvm_stack3 = value;
    }
    jvm_sp = jvm_sp + 1;
}

// Pop value from operand stack
int jvm_pop() {
    jvm_sp = jvm_sp - 1;
    if (jvm_sp == 0) {
        return jvm_stack0;
    } else if (jvm_sp == 1) {
        return jvm_stack1;
    } else if (jvm_sp == 2) {
        return jvm_stack2;
    } else if (jvm_sp == 3) {
        return jvm_stack3;
    }
    return 0;
}

// Get local variable
int jvm_get_local(int index) {
    if (index == 0) {
        return jvm_local0;
    } else if (index == 1) {
        return jvm_local1;
    } else if (index == 2) {
        return jvm_local2;
    } else if (index == 3) {
        return jvm_local3;
    }
    return 0;
}

// Set local variable
void jvm_set_local(int index, int value) {
    if (index == 0) {
        jvm_local0 = value;
    } else if (index == 1) {
        jvm_local1 = value;
    } else if (index == 2) {
        jvm_local2 = value;
    } else if (index == 3) {
        jvm_local3 = value;
    }
}

// Get bytecode instruction
int jvm_get_bytecode(int pc) {
    if (pc >= 0 && pc < bytecode_size) {
        return bytecode[pc];
    }
    return 177; // RETURN if out of bounds
}

// Execute bytecode
int jvm_execute() {
    jvm_init();
    
    while (jvm_pc < bytecode_size) {
        int opcode = jvm_get_bytecode(jvm_pc);
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
            int value = jvm_get_bytecode(jvm_pc);
            jvm_pc = jvm_pc + 1;
            jvm_push(value);
        } else if (opcode == 17) { // OP_SIPUSH
            int value = jvm_get_bytecode(jvm_pc);
            jvm_pc = jvm_pc + 1;
            jvm_push(value);
        } else if (opcode == 26) { // OP_ILOAD_0
            jvm_push(jvm_get_local(0));
        } else if (opcode == 27) { // OP_ILOAD_1
            jvm_push(jvm_get_local(1));
        } else if (opcode == 28) { // OP_ILOAD_2
            jvm_push(jvm_get_local(2));
        } else if (opcode == 29) { // OP_ILOAD_3
            jvm_push(jvm_get_local(3));
        } else if (opcode == 59) { // OP_ISTORE_0
            jvm_set_local(0, jvm_pop());
        } else if (opcode == 60) { // OP_ISTORE_1
            jvm_set_local(1, jvm_pop());
        } else if (opcode == 61) { // OP_ISTORE_2
            jvm_set_local(2, jvm_pop());
        } else if (opcode == 62) { // OP_ISTORE_3
            jvm_set_local(3, jvm_pop());
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
            jvm_push(a % b);  // Uses our MOD instruction!
        } else if (opcode == 172) { // OP_IRETURN
            return jvm_pop();
        } else if (opcode == 177) { // OP_RETURN
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
    // Execute the Java bytecode
    int result = jvm_execute();
    
    // Return the result for verification
    return result;
}
