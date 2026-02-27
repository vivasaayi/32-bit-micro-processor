/*
 * Generated JVM Program for RISC Processor
 * Executes Java bytecode: []
 */

struct JVM {
    int stack[16];
    int sp;
    int locals[8];
};

int main() {
    struct JVM jvm;
    int bytecode[0];
    int pc;
    int opcode;
    int a;
    int b;
    int result;
    
    /* Initialize JVM */
    jvm.sp = 0;
    jvm.locals[0] = 0;
    jvm.locals[1] = 0;
    jvm.locals[2] = 0;
    
    /* Load bytecode program */
    
    
    /* Execute bytecode */
    pc = 0;
    while (pc < 0) {
        opcode = bytecode[pc];
        pc = pc + 1;
        
        /* BIPUSH: push byte value */
        if (opcode == 16) {
            /* Next byte is the value - simulate with 10 for now */
            jvm.stack[jvm.sp] = 10;
            jvm.sp = jvm.sp + 1;
        }
        
        /* ICONST_5: push 5 */
        if (opcode == 8) {
            jvm.stack[jvm.sp] = 5;
            jvm.sp = jvm.sp + 1;
        }
        
        /* ISTORE_0: store to local 0 */
        if (opcode == 59) {
            jvm.sp = jvm.sp - 1;
            jvm.locals[0] = jvm.stack[jvm.sp];
        }
        
        /* ISTORE_1: store to local 1 */
        if (opcode == 60) {
            jvm.sp = jvm.sp - 1;
            jvm.locals[1] = jvm.stack[jvm.sp];
        }
        
        /* ILOAD_0: load local 0 */
        if (opcode == 26) {
            jvm.stack[jvm.sp] = jvm.locals[0];
            jvm.sp = jvm.sp + 1;
        }
        
        /* ILOAD_1: load local 1 */
        if (opcode == 27) {
            jvm.stack[jvm.sp] = jvm.locals[1];
            jvm.sp = jvm.sp + 1;
        }
        
        /* IADD: add two integers */
        if (opcode == 96) {
            jvm.sp = jvm.sp - 1;
            b = jvm.stack[jvm.sp];
            jvm.sp = jvm.sp - 1;
            a = jvm.stack[jvm.sp];
            result = a + b;
            jvm.stack[jvm.sp] = result;
            jvm.sp = jvm.sp + 1;
        }
        
        /* ISTORE_2: store to local 2 */
        if (opcode == 61) {
            jvm.sp = jvm.sp - 1;
            jvm.locals[2] = jvm.stack[jvm.sp];
        }
        
        /* ILOAD_2: load local 2 */
        if (opcode == 28) {
            jvm.stack[jvm.sp] = jvm.locals[2];
            jvm.sp = jvm.sp + 1;
        }
        
        /* IRETURN: return integer */
        if (opcode == 172) {
            jvm.sp = jvm.sp - 1;
            return jvm.stack[jvm.sp];
        }
    }
    
    return 0;
}
