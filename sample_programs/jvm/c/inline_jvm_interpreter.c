/*
 * Inline JVM Interpreter - No Functions with Parameters
 * Direct bytecode execution in main()
 */

struct JVM {
    int stack[32];
    int sp;
    int locals[8];
    int pc;
};

int main() {
    struct JVM jvm;
    jvm.sp = 0;
    jvm.pc = 0;
    
    /* Initialize locals */
    jvm.locals[0] = 0;
    jvm.locals[1] = 0;
    jvm.locals[2] = 0;
    jvm.locals[3] = 0;
    
    /* Bytecode program: 10 + 5 * 2 = 20 */
    int bytecode[8];
    bytecode[0] = 16;  /* BIPUSH */
    bytecode[1] = 10;  /* value 10 */
    bytecode[2] = 16;  /* BIPUSH */
    bytecode[3] = 5;   /* value 5 */
    bytecode[4] = 16;  /* BIPUSH */
    bytecode[5] = 2;   /* value 2 */
    bytecode[6] = 104; /* IMUL */
    bytecode[7] = 96;  /* IADD */
    
    /* Execute bytecode */
    jvm.pc = 0;
    while (jvm.pc < 8) {
        int opcode = bytecode[jvm.pc];
        jvm.pc = jvm.pc + 1;
        
        if (opcode == 16) {
            /* BIPUSH: Push byte */
            int value = bytecode[jvm.pc];
            jvm.pc = jvm.pc + 1;
            jvm.stack[jvm.sp] = value;
            jvm.sp = jvm.sp + 1;
        } else if (opcode == 96) {
            /* IADD: Add two integers */
            jvm.sp = jvm.sp - 1;
            int b = jvm.stack[jvm.sp];
            jvm.sp = jvm.sp - 1;
            int a = jvm.stack[jvm.sp];
            int result = a + b;
            jvm.stack[jvm.sp] = result;
            jvm.sp = jvm.sp + 1;
        } else if (opcode == 104) {
            /* IMUL: Multiply two integers */
            jvm.sp = jvm.sp - 1;
            int b = jvm.stack[jvm.sp];
            jvm.sp = jvm.sp - 1;
            int a = jvm.stack[jvm.sp];
            int result = a * b;
            jvm.stack[jvm.sp] = result;
            jvm.sp = jvm.sp + 1;
        } else if (opcode == 112) {
            /* IREM: Modulo operation */
            jvm.sp = jvm.sp - 1;
            int b = jvm.stack[jvm.sp];
            jvm.sp = jvm.sp - 1;
            int a = jvm.stack[jvm.sp];
            int result = a % b;
            jvm.stack[jvm.sp] = result;
            jvm.sp = jvm.sp + 1;
        }
    }
    
    /* Return top of stack */
    jvm.sp = jvm.sp - 1;
    return jvm.stack[jvm.sp];
}
