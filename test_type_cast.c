typedef struct {
    int sp;
} JVM;

JVM* test_func(void) {
    JVM* jvm = (JVM*)malloc(sizeof(JVM));
    return jvm;
}

int main() {
    return 0;
}
