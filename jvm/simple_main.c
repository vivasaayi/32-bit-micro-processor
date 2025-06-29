#include "jvm.h"

/* Simple test programs written as bytecode arrays */

/* Test 1: Simple arithmetic - compute 5 + 3 * 2 */
int test_arithmetic[] = {
    OP_ICONST_5,    /* Push 5 */
    OP_ICONST_3,    /* Push 3 */
    OP_ICONST_2,    /* Push 2 */
    OP_IMUL,        /* 3 * 2 = 6 */
    OP_IADD,        /* 5 + 6 = 11 */
    OP_IRETURN      /* Return 11 */
};

/* Test 2: Local variables - store and load */
int test_locals[] = {
    OP_BIPUSH, 42,      /* Push 42 */
    OP_ISTORE_0,        /* Store in local 0 */
    OP_BIPUSH, 10,      /* Push 10 */
    OP_ISTORE_1,        /* Store in local 1 */
    OP_ILOAD_0,         /* Load local 0 (42) */
    OP_ILOAD_1,         /* Load local 1 (10) */
    OP_IADD,            /* 42 + 10 = 52 */
    OP_IRETURN          /* Return 52 */
};

void run_test(const char* name, int* bytecode, int length) {
    printf("Running test\n");
    
    JVM* jvm = jvm_create();
    if (!jvm) {
        printf("Failed to create JVM\n");
        return;
    }
    
    printf("Executing bytecode\n");
    int result = jvm_execute(jvm, bytecode, length);
    printf("Test completed\n");
    
    jvm_destroy(jvm);
}

int main() {
    printf("Starting JVM Tests\n");
    
    run_test("Arithmetic", test_arithmetic, sizeof(test_arithmetic));
    run_test("Locals", test_locals, sizeof(test_locals));
    
    printf("All tests completed\n");
    return 0;
}
