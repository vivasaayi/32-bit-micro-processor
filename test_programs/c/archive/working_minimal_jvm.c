/*
 * Working Minimal JVM Interpreter
 * Uses only features we know work in our enhanced C compiler
 */

struct Value {
    int i;
};

struct JVM {
    int stack_data[64];
    int sp;
    int locals_data[16];
    int heap_data[256];
    int heap_ptr;
};

int main() {
    struct JVM jvm;
    jvm.sp = 0;
    jvm.heap_ptr = 0;
    
    /* Test basic JVM stack operations */
    /* Simulate: push 10, push 5, add, result should be 15 */
    
    /* Push 10 */
    jvm.stack_data[jvm.sp] = 10;
    jvm.sp = jvm.sp + 1;
    
    /* Push 5 */
    jvm.stack_data[jvm.sp] = 5;
    jvm.sp = jvm.sp + 1;
    
    /* IADD: pop two values, add, push result */
    jvm.sp = jvm.sp - 1;
    int val2 = jvm.stack_data[jvm.sp];
    jvm.sp = jvm.sp - 1;
    int val1 = jvm.stack_data[jvm.sp];
    
    int result = val1 + val2;
    
    jvm.stack_data[jvm.sp] = result;
    jvm.sp = jvm.sp + 1;
    
    /* Pop final result */
    jvm.sp = jvm.sp - 1;
    int final_result = jvm.stack_data[jvm.sp];
    
    return final_result;
}
