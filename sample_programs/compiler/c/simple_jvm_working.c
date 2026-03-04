/* Simplified JVM implementation that works with your compiler */

enum Opcode {
    OP_ICONST_5     = 8,
    OP_ICONST_3     = 6,
    OP_ICONST_2     = 5,
    OP_IMUL         = 104,
    OP_IADD         = 96,
    OP_IRETURN      = 172
};

int stack[100];
int sp = 0;

void jvm_push(int value) {
    stack[sp] = value;
    sp = sp + 1;
}

int jvm_pop() {
    sp = sp - 1;
    return stack[sp];
}

int main() {
    /* Simulate bytecode execution for: 5 + 3 * 2 */
    int bytecode[] = {8, 6, 5, 104, 96, 172};
    int pc = 0;
    
    while (pc < 6) {
        int opcode = bytecode[pc];
        pc = pc + 1;
        
        if (opcode == 8) {          /* OP_ICONST_5 */
            jvm_push(5);
        }
        if (opcode == 6) {          /* OP_ICONST_3 */
            jvm_push(3);
        }
        if (opcode == 5) {          /* OP_ICONST_2 */
            jvm_push(2);
        }
        if (opcode == 104) {        /* OP_IMUL */
            int b = jvm_pop();
            int a = jvm_pop();
            jvm_push(a * b);
        }
        if (opcode == 96) {         /* OP_IADD */
            int b = jvm_pop();
            int a = jvm_pop();
            jvm_push(a + b);
        }
        if (opcode == 172) {        /* OP_IRETURN */
            return jvm_pop();
        }
    }
    
    return 0;
}
