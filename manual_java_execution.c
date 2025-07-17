/*
 * Manual JVM Execution for SimpleArithmetic.java
 * Executes: int a=10; int b=5; return a+b; (should return 15)
 */

struct JVM {
    int stack[8];
    int sp;
    int locals[4];
};

int main() {
    struct JVM jvm;
    int result;
    
    /* Initialize JVM */
    jvm.sp = 0;
    jvm.locals[0] = 0;
    jvm.locals[1] = 0;
    jvm.locals[2] = 0;
    
    /* Manual execution of Java bytecode: */
    /* bipush 10 */
    jvm.stack[jvm.sp] = 10;
    jvm.sp = jvm.sp + 1;
    
    /* istore_0 (store 10 in local variable 0) */
    jvm.sp = jvm.sp - 1;
    jvm.locals[0] = jvm.stack[jvm.sp];
    
    /* iconst_5 */
    jvm.stack[jvm.sp] = 5;
    jvm.sp = jvm.sp + 1;
    
    /* istore_1 (store 5 in local variable 1) */
    jvm.sp = jvm.sp - 1;
    jvm.locals[1] = jvm.stack[jvm.sp];
    
    /* iload_0 (load local variable 0) */
    jvm.stack[jvm.sp] = jvm.locals[0];
    jvm.sp = jvm.sp + 1;
    
    /* iload_1 (load local variable 1) */
    jvm.stack[jvm.sp] = jvm.locals[1];
    jvm.sp = jvm.sp + 1;
    
    /* iadd (add top two stack values) */
    jvm.sp = jvm.sp - 1;
    int b = jvm.stack[jvm.sp];
    jvm.sp = jvm.sp - 1;
    int a = jvm.stack[jvm.sp];
    result = a + b;
    jvm.stack[jvm.sp] = result;
    jvm.sp = jvm.sp + 1;
    
    /* istore_2 (store result in local variable 2) */
    jvm.sp = jvm.sp - 1;
    jvm.locals[2] = jvm.stack[jvm.sp];
    
    /* iload_2 (load result) */
    jvm.stack[jvm.sp] = jvm.locals[2];
    jvm.sp = jvm.sp + 1;
    
    /* ireturn (return top of stack) */
    jvm.sp = jvm.sp - 1;
    result = jvm.stack[jvm.sp];
    
    return result;
}
