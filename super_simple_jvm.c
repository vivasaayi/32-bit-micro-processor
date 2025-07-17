/*
 * Super Simple JVM - Only IF statements
 */

struct JVM {
    int stack[8];
    int sp;
};

int main() {
    struct JVM jvm;
    int a;
    int b;
    int result;
    
    jvm.sp = 0;
    
    /* Test: 20 + 15 = 35 */
    /* Push 20 */
    jvm.stack[jvm.sp] = 20;
    jvm.sp = jvm.sp + 1;
    
    /* Push 15 */
    jvm.stack[jvm.sp] = 15;
    jvm.sp = jvm.sp + 1;
    
    /* Add */
    jvm.sp = jvm.sp - 1;
    b = jvm.stack[jvm.sp];
    jvm.sp = jvm.sp - 1;
    a = jvm.stack[jvm.sp];
    result = a + b;
    
    /* Push result */
    jvm.stack[jvm.sp] = result;
    jvm.sp = jvm.sp + 1;
    
    /* Get final result */
    jvm.sp = jvm.sp - 1;
    result = jvm.stack[jvm.sp];
    
    return result;
}
