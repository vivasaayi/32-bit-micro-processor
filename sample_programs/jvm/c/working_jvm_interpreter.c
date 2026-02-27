/*
 * JVM Interpreter - Working Version
 * No function parameters - uses global state
 */

struct JVM {
    int stack[64];
    int sp;
    int locals[16];
    int pc;
    int heap[128];
    int heap_ptr;
};

/* Global JVM instance */
struct JVM g_jvm;

void jvm_push_int(int value) {
    g_jvm.stack[g_jvm.sp] = value;
    g_jvm.sp = g_jvm.sp + 1;
}

int jvm_pop_int() {
    g_jvm.sp = g_jvm.sp - 1;
    return g_jvm.stack[g_jvm.sp];
}

int jvm_execute_bytecode(int* bytecode, int length) {
    g_jvm.pc = 0;
    
    while (g_jvm.pc < length) {
        int opcode = bytecode[g_jvm.pc];
        g_jvm.pc = g_jvm.pc + 1;
        
        if (opcode == 3) {
            /* ICONST_0 */
            jvm_push_int(0);
        } else if (opcode == 4) {
            /* ICONST_1 */
            jvm_push_int(1);
        } else if (opcode == 16) {
            /* BIPUSH */
            int value = bytecode[g_jvm.pc];
            g_jvm.pc = g_jvm.pc + 1;
            jvm_push_int(value);
        } else if (opcode == 96) {
            /* IADD */
            int b = jvm_pop_int();
            int a = jvm_pop_int();
            jvm_push_int(a + b);
        } else if (opcode == 100) {
            /* ISUB */
            int b = jvm_pop_int();
            int a = jvm_pop_int();
            jvm_push_int(a - b);
        } else if (opcode == 104) {
            /* IMUL */
            int b = jvm_pop_int();
            int a = jvm_pop_int();
            jvm_push_int(a * b);
        } else if (opcode == 108) {
            /* IDIV */
            int b = jvm_pop_int();
            int a = jvm_pop_int();
            if (b != 0) {
                jvm_push_int(a / b);
            }
        } else if (opcode == 112) {
            /* IREM */
            int b = jvm_pop_int();
            int a = jvm_pop_int();
            if (b != 0) {
                jvm_push_int(a % b);
            }
        } else if (opcode == 172) {
            /* IRETURN */
            return jvm_pop_int();
        }
    }
    
    return 0;
}

int main() {
    /* Initialize JVM */
    g_jvm.sp = 0;
    g_jvm.pc = 0;
    g_jvm.heap_ptr = 0;
    
    /* Test: 15 + 25 = 40 */
    int program[5];
    program[0] = 16;  /* BIPUSH */
    program[1] = 15;  /* value 15 */
    program[2] = 16;  /* BIPUSH */
    program[3] = 25;  /* value 25 */
    program[4] = 96;  /* IADD */
    
    int result = jvm_execute_bytecode(program, 5);
    
    return result;
}
