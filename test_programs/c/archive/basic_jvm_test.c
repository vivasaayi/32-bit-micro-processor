/*
 * Basic JVM test for enhanced C compiler
 * Tests basic JVM structures without complex features
 */

// Simple value structure
struct Value {
    int i;
};

// Simple JVM structure (no arrays in struct members yet)
struct JVM {
    int sp;
    int heap_ptr;
};

// Basic JVM operations
struct JVM* jvm_create() {
    int jvm_size = sizeof(struct JVM);
    int ptr = malloc(jvm_size);
    struct JVM* jvm = (struct JVM*)ptr;
    
    jvm->sp = 0;
    jvm->heap_ptr = 0;
    
    return jvm;
}

void jvm_set_sp(struct JVM* jvm, int sp) {
    jvm->sp = sp;
}

int jvm_get_sp(struct JVM* jvm) {
    return jvm->sp;
}

int main() {
    struct JVM* jvm = jvm_create();
    
    // Test operations
    jvm_set_sp(jvm, 42);
    int result = jvm_get_sp(jvm);
    
    free((int)jvm);
    
    return result;
}
