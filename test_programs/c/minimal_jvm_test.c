/*
 * Minimal JVM interpreter test for enhanced C compiler
 * Tests core JVM structures and malloc usage
 */

// JVM structures
struct Value {
    int i;
};

struct JVM {
    struct Value stack[16];  // Small stack for testing
    int sp;
    int heap[64];           // Small heap for testing  
    int heap_ptr;
};

// Memory allocation functions
int malloc(int size) {
    // Simple heap allocation - this would be a library function
    // For now, just return a fixed address
    return 0x30000;
}

void free(int ptr) {
    // Simple free - no-op for now
}

// JVM operations
struct JVM* jvm_create() {
    int jvm_size = sizeof(struct JVM);
    int ptr = malloc(jvm_size);
    struct JVM* jvm = (struct JVM*)ptr;
    
    jvm->sp = 0;
    jvm->heap_ptr = 0;
    
    return jvm;
}

void jvm_push(struct JVM* jvm, struct Value value) {
    jvm->stack[jvm->sp] = value;
    jvm->sp = jvm->sp + 1;
}

struct Value jvm_pop(struct JVM* jvm) {
    jvm->sp = jvm->sp - 1;
    return jvm->stack[jvm->sp];
}

int main() {
    struct JVM* jvm = jvm_create();
    
    // Test push and pop
    struct Value val;
    val.i = 42;
    jvm_push(jvm, val);
    
    struct Value result = jvm_pop(jvm);
    
    free((int)jvm);
    
    return result.i;
}
