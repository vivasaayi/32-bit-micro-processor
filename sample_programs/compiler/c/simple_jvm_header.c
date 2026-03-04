/* Simplified JVM header using only supported features */

enum Opcode {
    OP_NOP          = 0,
    OP_ICONST_M1    = 2,
    OP_ICONST_0     = 3,
    OP_ICONST_1     = 4,
    OP_ICONST_2     = 5,
    OP_ICONST_3     = 6,
    OP_ICONST_4     = 7,
    OP_ICONST_5     = 8,
    OP_BIPUSH       = 16,
    OP_ILOAD        = 21,
    OP_ISTORE       = 54,
    OP_IADD         = 96,
    OP_ISUB         = 100,
    OP_IMUL         = 104,
    OP_IDIV         = 108,
    OP_IRETURN      = 172,
    OP_HALT         = 255
};

int stack[1024];
int sp = 0;
int locals[256];

void jvm_push(int value) {
    stack[sp] = value;
    sp = sp + 1;
}

int jvm_pop() {
    sp = sp - 1;
    return stack[sp];
}

int jvm_execute(int bytecode[], int length) {
    int pc = 0;
    
    while (pc < length) {
        int opcode = bytecode[pc];
        pc = pc + 1;
        
        if (opcode == OP_ICONST_0) {
            jvm_push(0);
        }
        if (opcode == OP_ICONST_1) {
            jvm_push(1);
        }
        if (opcode == OP_ICONST_2) {
            jvm_push(2);
        }
        if (opcode == OP_ICONST_3) {
            jvm_push(3);
        }
        if (opcode == OP_ICONST_4) {
            jvm_push(4);
        }
        if (opcode == OP_ICONST_5) {
            jvm_push(5);
        }
        if (opcode == OP_BIPUSH) {
            int value = bytecode[pc];
            pc = pc + 1;
            jvm_push(value);
        }
        if (opcode == OP_IADD) {
            int b = jvm_pop();
            int a = jvm_pop();
            jvm_push(a + b);
        }
        if (opcode == OP_ISUB) {
            int b = jvm_pop();
            int a = jvm_pop();
            jvm_push(a - b);
        }
        if (opcode == OP_IMUL) {
            int b = jvm_pop();
            int a = jvm_pop();
            jvm_push(a * b);
        }
        if (opcode == OP_IRETURN) {
            return jvm_pop();
        }
    }
    
    return 0;
}

int main() {
    /* Test: compute 5 + 3 * 2 = 11 */
    int program[] = {OP_ICONST_5, OP_ICONST_3, OP_ICONST_2, OP_IMUL, OP_IADD, OP_IRETURN};
    int result = jvm_execute(program, 6);
    return result;
}
