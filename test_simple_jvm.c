// Simplified JVM test without includes

// Basic JVM types and constants
typedef struct {
    int i;
} Value;

typedef struct {
    int sp;
    Value stack[1024];
} JVM;

JVM* jvm_create(void) {
    JVM* jvm = (JVM*)malloc(sizeof(JVM));
    if (!jvm) {
        return NULL;
    }
    jvm->sp = 0;
    return jvm;
}

void jvm_destroy(JVM* jvm) {
    if (jvm) {
        free(jvm);
    }
}

int main() {
    JVM* jvm = jvm_create();
    jvm_destroy(jvm);
    return 0;
}
