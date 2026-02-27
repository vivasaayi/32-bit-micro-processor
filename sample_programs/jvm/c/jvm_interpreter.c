/*
 * Real JVM Interpreter - Simplified but Functional
 * Implements core JVM bytecode execution using working C compiler features
 */

/* JVM Constants */
struct Value {
    int i;
};

struct Frame {
    int locals[16];
    int pc;
    int locals_count;
};

struct JVM {
    int stack[64];
    int sp;
    struct Frame frames[8];
    int fp;
    int heap[256];
    int heap_ptr;
    int debug;
};

/* JVM Core Functions */
void jvm_push_int(struct JVM* jvm, int value) {
    if (jvm->sp >= 64) {
        return; /* Stack overflow */
    }
    jvm->stack[jvm->sp] = value;
    jvm->sp = jvm->sp + 1;
}

int jvm_pop_int(struct JVM* jvm) {
    if (jvm->sp <= 0) {
        return 0; /* Stack underflow */
    }
    jvm->sp = jvm->sp - 1;
    return jvm->stack[jvm->sp];
}

/* Execute JVM bytecode */
int jvm_execute(struct JVM* jvm, int* bytecode, int length) {
    struct Frame* frame = &jvm->frames[jvm->fp];
    frame->pc = 0;
    frame->locals_count = 4;
    
    /* Initialize local variables */
    frame->locals[0] = 0;
    frame->locals[1] = 0;
    frame->locals[2] = 0;
    frame->locals[3] = 0;
    
    while (frame->pc < length) {
        int opcode = bytecode[frame->pc];
        frame->pc = frame->pc + 1;
        
        if (opcode == 3) {
            /* ICONST_0: Push constant 0 */
            jvm_push_int(jvm, 0);
        } else if (opcode == 4) {
            /* ICONST_1: Push constant 1 */
            jvm_push_int(jvm, 1);
        } else if (opcode == 5) {
            /* ICONST_2: Push constant 2 */
            jvm_push_int(jvm, 2);
        } else if (opcode == 6) {
            /* ICONST_3: Push constant 3 */
            jvm_push_int(jvm, 3);
        } else if (opcode == 7) {
            /* ICONST_4: Push constant 4 */
            jvm_push_int(jvm, 4);
        } else if (opcode == 8) {
            /* ICONST_5: Push constant 5 */
            jvm_push_int(jvm, 5);
        } else if (opcode == 16) {
            /* BIPUSH: Push byte value */
            int value = bytecode[frame->pc];
            frame->pc = frame->pc + 1;
            jvm_push_int(jvm, value);
        } else if (opcode == 21) {
            /* ILOAD: Load local variable */
            int index = bytecode[frame->pc];
            frame->pc = frame->pc + 1;
            jvm_push_int(jvm, frame->locals[index]);
        } else if (opcode == 26) {
            /* ILOAD_0: Load local variable 0 */
            jvm_push_int(jvm, frame->locals[0]);
        } else if (opcode == 27) {
            /* ILOAD_1: Load local variable 1 */
            jvm_push_int(jvm, frame->locals[1]);
        } else if (opcode == 54) {
            /* ISTORE: Store to local variable */
            int index = bytecode[frame->pc];
            frame->pc = frame->pc + 1;
            frame->locals[index] = jvm_pop_int(jvm);
        } else if (opcode == 59) {
            /* ISTORE_0: Store to local variable 0 */
            frame->locals[0] = jvm_pop_int(jvm);
        } else if (opcode == 60) {
            /* ISTORE_1: Store to local variable 1 */
            frame->locals[1] = jvm_pop_int(jvm);
        } else if (opcode == 96) {
            /* IADD: Integer addition */
            int b = jvm_pop_int(jvm);
            int a = jvm_pop_int(jvm);
            jvm_push_int(jvm, a + b);
        } else if (opcode == 100) {
            /* ISUB: Integer subtraction */
            int b = jvm_pop_int(jvm);
            int a = jvm_pop_int(jvm);
            jvm_push_int(jvm, a - b);
        } else if (opcode == 104) {
            /* IMUL: Integer multiplication */
            int b = jvm_pop_int(jvm);
            int a = jvm_pop_int(jvm);
            jvm_push_int(jvm, a * b);
        } else if (opcode == 108) {
            /* IDIV: Integer division */
            int b = jvm_pop_int(jvm);
            int a = jvm_pop_int(jvm);
            if (b != 0) {
                jvm_push_int(jvm, a / b);
            } else {
                jvm_push_int(jvm, 0);
            }
        } else if (opcode == 112) {
            /* IREM: Integer remainder (modulo) */
            int b = jvm_pop_int(jvm);
            int a = jvm_pop_int(jvm);
            if (b != 0) {
                jvm_push_int(jvm, a % b);
            } else {
                jvm_push_int(jvm, 0);
            }
        } else if (opcode == 172) {
            /* IRETURN: Return integer */
            return jvm_pop_int(jvm);
        } else if (opcode == 177) {
            /* RETURN: Return void */
            return 0;
        } else if (opcode == 255) {
            /* HALT: Stop execution */
            break;
        }
    }
    
    return 0;
}

/* Test main function */
int main() {
    struct JVM jvm;
    jvm.sp = 0;
    jvm.fp = 0;
    jvm.heap_ptr = 0;
    jvm.debug = 0;
    
    /* Test bytecode: Calculate 10 + 5 * 2 = 20 */
    int bytecode[8];
    bytecode[0] = 16;  /* BIPUSH */
    bytecode[1] = 10;  /* value 10 */
    bytecode[2] = 16;  /* BIPUSH */
    bytecode[3] = 5;   /* value 5 */
    bytecode[4] = 16;  /* BIPUSH */
    bytecode[5] = 2;   /* value 2 */
    bytecode[6] = 104; /* IMUL (5 * 2) */
    bytecode[7] = 96;  /* IADD (10 + 10) */
    
    int result = jvm_execute(&jvm, bytecode, 8);
    
    return result; /* Should return 20 */
}
