/*
 * Minimal Working JVM for Enhanced C Compiler Test
 */

struct Value {
    int i;
};

struct JVM {
    int stack_values[64];
    int sp;
};

void jvm_push(struct JVM* jvm, int value) {
    jvm->stack_values[jvm->sp] = value;
    jvm->sp = jvm->sp + 1;
}

int jvm_pop(struct JVM* jvm) {
    jvm->sp = jvm->sp - 1;
    return jvm->stack_values[jvm->sp];
}

int main() {
    struct JVM jvm;
    jvm.sp = 0;
    
    /* Test: 10 + 5 = 15 */
    jvm_push(&jvm, 10);
    jvm_push(&jvm, 5);
    
    /* IADD operation */
    int b = jvm_pop(&jvm);
    int a = jvm_pop(&jvm);
    int result = a + b;
    jvm_push(&jvm, result);
    
    /* Get final result */
    int final_result = jvm_pop(&jvm);
    
    return final_result;
}
