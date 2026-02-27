/*
 * SIMPLIFIED GENERIC JVM INTERPRETER
 * 
 * This demonstrates how to make a JVM interpreter that can execute
 * different bytecode programs by changing the loaded program
 */

// JVM State - simplified
struct JVM {
    int stack0, stack1, stack2, stack3;
    int sp;
    int local0, local1, local2, local3;
    int pc;
};

// Program storage
struct Program {
    int bytecode0, bytecode1, bytecode2, bytecode3, bytecode4;
    int bytecode5, bytecode6, bytecode7, bytecode8, bytecode9;
    int length;
};

// Global state
struct JVM jvm;
struct Program current_program;

// Stack operations
void push_to_stack(int value) {
    if (jvm.sp == 0) {
        jvm.stack0 = value;
        jvm.sp = 1;
    } else if (jvm.sp == 1) {
        jvm.stack1 = value;
        jvm.sp = 2;
    } else if (jvm.sp == 2) {
        jvm.stack2 = value;
        jvm.sp = 3;
    } else if (jvm.sp == 3) {
        jvm.stack3 = value;
        jvm.sp = 4;
    }
}

int pop_from_stack() {
    if (jvm.sp == 4) {
        jvm.sp = 3;
        return jvm.stack3;
    } else if (jvm.sp == 3) {
        jvm.sp = 2;
        return jvm.stack2;
    } else if (jvm.sp == 2) {
        jvm.sp = 1;
        return jvm.stack1;
    } else if (jvm.sp == 1) {
        jvm.sp = 0;
        return jvm.stack0;
    }
    return 0;
}

// Get instruction from current program
int get_current_instruction() {
    if (jvm.pc == 0) return current_program.bytecode0;
    if (jvm.pc == 1) return current_program.bytecode1;
    if (jvm.pc == 2) return current_program.bytecode2;
    if (jvm.pc == 3) return current_program.bytecode3;
    if (jvm.pc == 4) return current_program.bytecode4;
    if (jvm.pc == 5) return current_program.bytecode5;
    if (jvm.pc == 6) return current_program.bytecode6;
    if (jvm.pc == 7) return current_program.bytecode7;
    if (jvm.pc == 8) return current_program.bytecode8;
    if (jvm.pc == 9) return current_program.bytecode9;
    return 0;
}

// Execute current program
int execute_current_program() {
    jvm.pc = 0;
    jvm.sp = 0;
    
    while (jvm.pc < current_program.length) {
        int opcode = get_current_instruction();
        
        // ICONST_5 (8)
        if (opcode == 8) {
            push_to_stack(5);
        }
        // BIPUSH (16) - next byte is the value
        else if (opcode == 16) {
            jvm.pc = jvm.pc + 1;
            int value = get_current_instruction();
            push_to_stack(value);
        }
        // ILOAD_0 (26)
        else if (opcode == 26) {
            push_to_stack(jvm.local0);
        }
        // ILOAD_1 (27)
        else if (opcode == 27) {
            push_to_stack(jvm.local1);
        }
        // ISTORE_0 (59)
        else if (opcode == 59) {
            jvm.local0 = pop_from_stack();
        }
        // ISTORE_1 (60)
        else if (opcode == 60) {
            jvm.local1 = pop_from_stack();
        }
        // ISTORE_2 (61)
        else if (opcode == 61) {
            jvm.local2 = pop_from_stack();
        }
        // IADD (96)
        else if (opcode == 96) {
            int b = pop_from_stack();
            int a = pop_from_stack();
            push_to_stack(a + b);
        }
        // IMUL (104)
        else if (opcode == 104) {
            int b = pop_from_stack();
            int a = pop_from_stack();
            push_to_stack(a * b);
        }
        // IREM (112) - modulo
        else if (opcode == 112) {
            int b = pop_from_stack();
            int a = pop_from_stack();
            push_to_stack(a % b);
        }
        // IRETURN (172)
        else if (opcode == 172) {
            return pop_from_stack();
        }
        
        jvm.pc = jvm.pc + 1;
    }
    
    return 0;
}

// Load SimpleArithmetic program: 10 + 5 = 15
void load_program_simple_arithmetic() {
    current_program.bytecode0 = 16;  // bipush
    current_program.bytecode1 = 10;  // 10
    current_program.bytecode2 = 59;  // istore_0
    current_program.bytecode3 = 8;   // iconst_5
    current_program.bytecode4 = 60;  // istore_1
    current_program.bytecode5 = 26;  // iload_0
    current_program.bytecode6 = 27;  // iload_1
    current_program.bytecode7 = 96;  // iadd
    current_program.bytecode8 = 172; // ireturn
    current_program.length = 9;
}

// Load different program: 7 * 3 = 21
void load_program_multiplication() {
    current_program.bytecode0 = 16;  // bipush
    current_program.bytecode1 = 7;   // 7
    current_program.bytecode2 = 16;  // bipush
    current_program.bytecode3 = 3;   // 3
    current_program.bytecode4 = 104; // imul
    current_program.bytecode5 = 172; // ireturn
    current_program.length = 6;
}

// Load modulo program: 17 % 5 = 2
void load_program_modulo() {
    current_program.bytecode0 = 16;  // bipush
    current_program.bytecode1 = 17;  // 17
    current_program.bytecode2 = 16;  // bipush  
    current_program.bytecode3 = 5;   // 5
    current_program.bytecode4 = 112; // irem (modulo)
    current_program.bytecode5 = 172; // ireturn
    current_program.length = 6;
}

int main() {
    // Test 1: SimpleArithmetic (10 + 5 = 15)
    load_program_simple_arithmetic();
    int result1 = execute_current_program();
    
    // Test 2: Multiplication (7 * 3 = 21)
    load_program_multiplication();
    int result2 = execute_current_program();
    
    // Test 3: Modulo (17 % 5 = 2)
    load_program_modulo();
    int result3 = execute_current_program();
    
    // Return success if all tests pass
    if (result1 == 15 && result2 == 21 && result3 == 2) {
        return 1;  // All programs executed correctly
    } else {
        return 0;  // Some program failed
    }
}
