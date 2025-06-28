/*
 * Simplified JVM Interpreter for Enhanced C Compiler
 */

struct Value {
    int i;
};

struct Frame {
    struct Value locals[16];
    int pc;
    int locals_count;
};

struct JVM {
    struct Value stack[64];
    int sp;
    struct Frame frames[8];
    int fp;
    int heap[256];
    int heap_ptr;
};

void jvm_push(struct JVM* jvm, struct Value value) {
    jvm->stack[jvm->sp] = value;
    jvm->sp = jvm->sp + 1;
}

struct Value jvm_pop(struct JVM* jvm) {
    jvm->sp = jvm->sp - 1;
    return jvm->stack[jvm->sp];
}

int main() {
    struct JVM jvm;
    jvm.sp = 0;
    jvm.fp = 0;
    jvm.heap_ptr = 0;
    
    /* Test JVM operations: 10 + 5 = 15 */
    struct Value val1;
    val1.i = 10;
    jvm_push(&jvm, val1);
    
    struct Value val2;
    val2.i = 5;
    jvm_push(&jvm, val2);
    
    /* Execute IADD */
    struct Value b = jvm_pop(&jvm);
    struct Value a = jvm_pop(&jvm);
    struct Value result;
    result.i = a.i + b.i;
    jvm_push(&jvm, result);
    
    /* Get result */
    struct Value final_result = jvm_pop(&jvm);
    
    return final_result.i;
}
