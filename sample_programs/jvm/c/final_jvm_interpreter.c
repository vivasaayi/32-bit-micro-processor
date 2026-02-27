/*
 * Final JVM Interpreter - Fully Compatible
 */

struct JVM {
    int stack[16];
    int sp;
    int pc;
};

int main() {
    struct JVM jvm;
    int bytecode[6];
    int opcode;
    int value;
    int a;
    int b;
    int result;
    
    /* Initialize JVM */
    jvm.sp = 0;
    jvm.pc = 0;
    
    /* Program: push 15, push 10, add (should give 25) */
    bytecode[0] = 16;  /* BIPUSH */
    bytecode[1] = 15;  /* value 15 */
    bytecode[2] = 16;  /* BIPUSH */
    bytecode[3] = 10;  /* value 10 */
    bytecode[4] = 96;  /* IADD */
    bytecode[5] = 172; /* IRETURN (not implemented, just end) */
    
    /* Execute bytecode */
    while (jvm.pc < 5) {
        opcode = bytecode[jvm.pc];
        jvm.pc = jvm.pc + 1;
        
        if (opcode == 16) {
            /* BIPUSH */
            value = bytecode[jvm.pc];
            jvm.pc = jvm.pc + 1;
            jvm.stack[jvm.sp] = value;
            jvm.sp = jvm.sp + 1;
        } else if (opcode == 96) {
            /* IADD */
            jvm.sp = jvm.sp - 1;
            b = jvm.stack[jvm.sp];
            jvm.sp = jvm.sp - 1;
            a = jvm.stack[jvm.sp];
            result = a + b;
            jvm.stack[jvm.sp] = result;
            jvm.sp = jvm.sp + 1;
        }
    }
    
    /* Get result */
    jvm.sp = jvm.sp - 1;
    result = jvm.stack[jvm.sp];
    
    return result;
}
