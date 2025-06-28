/*
 * Debug struct with array member
 */

struct JVM {
    int values[8];
    int sp;
};

int main() {
    struct JVM jvm;
    jvm.sp = 0;
    jvm.values[0] = 42;
    return jvm.values[0];
}
