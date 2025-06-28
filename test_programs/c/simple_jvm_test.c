/*
 * Simplified JVM for RISC Processor
 * Supports basic Java bytecode execution with integer operations
 */

// Basic JVM data structures
typedef struct {
    int i;
} Value;

typedef struct {
    Value stack[64];    // Operand stack (reduced size)
    int sp;             // Stack pointer
    int locals[16];     // Local variables (reduced size)
    int pc;             // Program counter
} Frame;

typedef struct {
    Frame frame;        // Single frame (simplified)
    int heap[256];      // Simple heap (reduced size)
    int heap_ptr;       // Heap allocation pointer
} JVM;

// Java bytecodes (subset)
#define OP_ICONST_0     0x03
#define OP_ICONST_1     0x04
#define OP_ICONST_2     0x05
#define OP_ICONST_3     0x06
#define OP_ICONST_4     0x07
#define OP_ICONST_5     0x08
#define OP_BIPUSH       0x10
#define OP_ILOAD_0      0x1a
#define OP_ILOAD_1      0x1b
#define OP_ILOAD_2      0x1c
#define OP_ILOAD_3      0x1d
#define OP_ISTORE_0     0x3b
#define OP_ISTORE_1     0x3c
#define OP_ISTORE_2     0x3d
#define OP_ISTORE_3     0x3e
#define OP_IADD         0x60
#define OP_ISUB         0x64
#define OP_IMUL         0x68
#define OP_IDIV         0x6c
#define OP_IREM         0x70
#define OP_RETURN       0xb1
#define OP_HALT         0xff

// Global JVM instance
JVM jvm;

// Initialize JVM
void jvm_init() {
    jvm.frame.sp = 0;
    jvm.frame.pc = 0;
    jvm.heap_ptr = 0;
    
    // Clear locals
    int i = 0;
    while (i < 16) {
        jvm.frame.locals[i] = 0;
        i = i + 1;
    }
}

// Push value onto operand stack
void jvm_push(int value) {
    Value v;
    v.i = value;
    jvm.frame.stack[jvm.frame.sp] = v;
    jvm.frame.sp = jvm.frame.sp + 1;
}

// Pop value from operand stack
int jvm_pop() {
    jvm.frame.sp = jvm.frame.sp - 1;
    return jvm.frame.stack[jvm.frame.sp].i;
}

// Execute bytecode
int jvm_execute(int bytecode[], int length) {
    jvm_init();
    
    while (jvm.frame.pc < length) {
        int opcode = bytecode[jvm.frame.pc];
        jvm.frame.pc = jvm.frame.pc + 1;
        
        if (opcode == OP_ICONST_0) {
            jvm_push(0);
        } else if (opcode == OP_ICONST_1) {
            jvm_push(1);
        } else if (opcode == OP_ICONST_2) {
            jvm_push(2);
        } else if (opcode == OP_ICONST_3) {
            jvm_push(3);
        } else if (opcode == OP_ICONST_4) {
            jvm_push(4);
        } else if (opcode == OP_ICONST_5) {
            jvm_push(5);
        } else if (opcode == OP_BIPUSH) {
            int value = bytecode[jvm.frame.pc];
            jvm.frame.pc = jvm.frame.pc + 1;
            jvm_push(value);
        } else if (opcode == OP_ILOAD_0) {
            jvm_push(jvm.frame.locals[0]);
        } else if (opcode == OP_ILOAD_1) {
            jvm_push(jvm.frame.locals[1]);
        } else if (opcode == OP_ILOAD_2) {
            jvm_push(jvm.frame.locals[2]);
        } else if (opcode == OP_ILOAD_3) {
            jvm_push(jvm.frame.locals[3]);
        } else if (opcode == OP_ISTORE_0) {
            jvm.frame.locals[0] = jvm_pop();
        } else if (opcode == OP_ISTORE_1) {
            jvm.frame.locals[1] = jvm_pop();
        } else if (opcode == OP_ISTORE_2) {
            jvm.frame.locals[2] = jvm_pop();
        } else if (opcode == OP_ISTORE_3) {
            jvm.frame.locals[3] = jvm_pop();
        } else if (opcode == OP_IADD) {
            int b = jvm_pop();
            int a = jvm_pop();
            jvm_push(a + b);
        } else if (opcode == OP_ISUB) {
            int b = jvm_pop();
            int a = jvm_pop();
            jvm_push(a - b);
        } else if (opcode == OP_IMUL) {
            int b = jvm_pop();
            int a = jvm_pop();
            jvm_push(a * b);
        } else if (opcode == OP_IDIV) {
            int b = jvm_pop();
            int a = jvm_pop();
            jvm_push(a / b);
        } else if (opcode == OP_IREM) {
            int b = jvm_pop();
            int a = jvm_pop();
            jvm_push(a % b);  // Uses our new MOD instruction!
        } else if (opcode == OP_RETURN) {
            break;
        } else if (opcode == OP_HALT) {
            break;
        }
    }
    
    // Return top of stack as result
    if (jvm.frame.sp > 0) {
        return jvm_pop();
    } else {
        return 0;
    }
}

// Test program: simple Java bytecode for "5 + 3 * 2"
// This translates to: ICONST_5, ICONST_3, ICONST_2, IMUL, IADD, RETURN
int test_program[] = {
    OP_ICONST_5,    // Push 5
    OP_ICONST_3,    // Push 3  
    OP_ICONST_2,    // Push 2
    OP_IMUL,        // 3 * 2 = 6
    OP_IADD,        // 5 + 6 = 11
    OP_RETURN       // Return result (11)
};

int main() {
    int result = jvm_execute(test_program, 6);
    
    // Verify result is 11
    if (result == 11) {
        return 1;  // Success
    } else {
        return 0;  // Failure
    }
}
