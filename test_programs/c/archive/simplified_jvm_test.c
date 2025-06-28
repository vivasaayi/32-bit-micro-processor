/*
 * Simplified JVM interpreter test for enhanced C compiler
 */

// JVM structures
struct Value {
    int i;
};

struct JVM {
    struct Value stack[8];  // Small stack for testing
    int sp;
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
    
    // Test push and pop
    struct Value val;
    val.i = 42;
    jvm_push(&jvm, val);
    
    struct Value result = jvm_pop(&jvm);
    
    return result.i;
}
