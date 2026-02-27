#include "jvm.h"

/* Simple test programs written as bytecode arrays */

/* Test 1: Simple arithmetic - compute 5 + 3 * 2 */
uint8_t test_arithmetic[] = {
    OP_ICONST_5,    /* Push 5 */
    OP_ICONST_3,    /* Push 3 */
    OP_ICONST_2,    /* Push 2 */
    OP_IMUL,        /* 3 * 2 = 6 */
    OP_IADD,        /* 5 + 6 = 11 */
    OP_IRETURN      /* Return 11 */
};

/* Test 2: Local variables - store and load */
uint8_t test_locals[] = {
    OP_BIPUSH, 42,      /* Push 42 */
    OP_ISTORE_0,        /* Store in local 0 */
    OP_BIPUSH, 10,      /* Push 10 */
    OP_ISTORE_1,        /* Store in local 1 */
    OP_ILOAD_0,         /* Load local 0 (42) */
    OP_ILOAD_1,         /* Load local 1 (10) */
    OP_IADD,            /* 42 + 10 = 52 */
    OP_IRETURN          /* Return 52 */
};

/* Test 3: Conditional branch - simple if statement */
uint8_t test_branch[] = {
    OP_BIPUSH, 10,      /* Push 10 */
    OP_BIPUSH, 5,       /* Push 5 */
    OP_IF_ICMPGT, 0, 6, /* If 10 > 5, jump +6 bytes */
    OP_ICONST_0,        /* Push 0 (false case) */
    OP_GOTO, 0, 3,      /* Jump over true case */
    OP_ICONST_1,        /* Push 1 (true case) */
    OP_IRETURN          /* Return result */
};

/* Test 4: Simple counting - just count to 3 and return */
uint8_t test_loop[] = {
    OP_ICONST_1,        /* counter = 1 */
    OP_ISTORE_0,        /* store in local 0 */
    OP_ILOAD_0,         /* load counter */
    OP_ICONST_1,        /* add 1 */
    OP_IADD,            
    OP_ISTORE_0,        /* counter = 2 */
    OP_ILOAD_0,         /* load counter */
    OP_ICONST_1,        /* add 1 */
    OP_IADD,            
    OP_ISTORE_0,        /* counter = 3 */
    OP_ILOAD_0,         /* load final value */
    OP_IRETURN          /* return 3 */
};

/* Test runner function */
void run_test(const char* name, uint8_t* bytecode, int length) {
    printf("\n=== Running test: %s ===\n", name);
    
    JVM* jvm = jvm_create();
    if (!jvm) {
        printf("Failed to create JVM\n");
        return;
    }
    
    printf("Executing bytecode...\n");
    int result = jvm_execute(jvm, bytecode, length);
    printf("Test result: %d\n", result);
    
    jvm_destroy(jvm);
}

/* Bytecode disassembler for debugging */
void disassemble(uint8_t* bytecode, int length) {
    printf("\nBytecode disassembly:\n");
    int pc = 0;
    
    while (pc < length) {
        printf("%04x: ", pc);
        uint8_t op = bytecode[pc++];
        
        switch (op) {
            case OP_NOP: printf("nop\n"); break;
            case OP_ICONST_M1: printf("iconst_m1\n"); break;
            case OP_ICONST_0: printf("iconst_0\n"); break;
            case OP_ICONST_1: printf("iconst_1\n"); break;
            case OP_ICONST_2: printf("iconst_2\n"); break;
            case OP_ICONST_3: printf("iconst_3\n"); break;
            case OP_ICONST_4: printf("iconst_4\n"); break;
            case OP_ICONST_5: printf("iconst_5\n"); break;
            case OP_BIPUSH:
                if (pc < length) printf("bipush %d\n", (int8_t)bytecode[pc++]);
                break;
            case OP_SIPUSH:
                if (pc + 1 < length) {
                    int16_t val = (int16_t)((bytecode[pc] << 8) | bytecode[pc + 1]);
                    pc += 2;
                    printf("sipush %d\n", val);
                }
                break;
            case OP_ILOAD: 
                if (pc < length) printf("iload %d\n", bytecode[pc++]);
                break;
            case OP_ILOAD_0: printf("iload_0\n"); break;
            case OP_ILOAD_1: printf("iload_1\n"); break;
            case OP_ILOAD_2: printf("iload_2\n"); break;
            case OP_ILOAD_3: printf("iload_3\n"); break;
            case OP_ISTORE:
                if (pc < length) printf("istore %d\n", bytecode[pc++]);
                break;
            case OP_ISTORE_0: printf("istore_0\n"); break;
            case OP_ISTORE_1: printf("istore_1\n"); break;
            case OP_ISTORE_2: printf("istore_2\n"); break;
            case OP_ISTORE_3: printf("istore_3\n"); break;
            case OP_IADD: printf("iadd\n"); break;
            case OP_ISUB: printf("isub\n"); break;
            case OP_IMUL: printf("imul\n"); break;
            case OP_IDIV: printf("idiv\n"); break;
            case OP_IREM: printf("irem\n"); break;
            case OP_INEG: printf("ineg\n"); break;
            case OP_IF_ICMPEQ:
                if (pc + 1 < length) {
                    int16_t offset = (int16_t)((bytecode[pc] << 8) | bytecode[pc + 1]);
                    pc += 2;
                    printf("if_icmpeq %d\n", offset);
                }
                break;
            case OP_IF_ICMPNE:
                if (pc + 1 < length) {
                    int16_t offset = (int16_t)((bytecode[pc] << 8) | bytecode[pc + 1]);
                    pc += 2;
                    printf("if_icmpne %d\n", offset);
                }
                break;
            case OP_IF_ICMPLT:
                if (pc + 1 < length) {
                    int16_t offset = (int16_t)((bytecode[pc] << 8) | bytecode[pc + 1]);
                    pc += 2;
                    printf("if_icmplt %d\n", offset);
                }
                break;
            case OP_IF_ICMPGE:
                if (pc + 1 < length) {
                    int16_t offset = (int16_t)((bytecode[pc] << 8) | bytecode[pc + 1]);
                    pc += 2;
                    printf("if_icmpge %d\n", offset);
                }
                break;
            case OP_IF_ICMPGT:
                if (pc + 1 < length) {
                    int16_t offset = (int16_t)((bytecode[pc] << 8) | bytecode[pc + 1]);
                    pc += 2;
                    printf("if_icmpgt %d\n", offset);
                }
                break;
            case OP_IF_ICMPLE:
                if (pc + 1 < length) {
                    int16_t offset = (int16_t)((bytecode[pc] << 8) | bytecode[pc + 1]);
                    pc += 2;
                    printf("if_icmple %d\n", offset);
                }
                break;
            case OP_GOTO:
                if (pc + 1 < length) {
                    int16_t offset = (int16_t)((bytecode[pc] << 8) | bytecode[pc + 1]);
                    pc += 2;
                    printf("goto %d\n", offset);
                }
                break;
            case OP_IRETURN: printf("ireturn\n"); break;
            case OP_RETURN: printf("return\n"); break;
            case OP_HALT: printf("halt\n"); break;
            default: printf("unknown_opcode 0x%02x\n", op); break;
        }
    }
    printf("\n");
}

int main() {
    printf("AruviJVM - Simple Java Bytecode Interpreter\n");
    printf("===========================================\n");
    
    /* Run all tests */
    run_test("Arithmetic (5 + 3 * 2)", test_arithmetic, sizeof(test_arithmetic));
    run_test("Local Variables (42 + 10)", test_locals, sizeof(test_locals));
    run_test("Conditional Branch (10 > 5)", test_branch, sizeof(test_branch));
    run_test("Simple Counting (1+1+1)", test_loop, sizeof(test_loop));
    
    /* Show disassembly of one test for educational purposes */
    printf("\n=== Disassembly Example (Arithmetic Test) ===");
    disassemble(test_arithmetic, sizeof(test_arithmetic));
    
    return 0;
}
