#include "jvm.h"

/* Create a new JVM instance */
JVM* jvm_create(void) {
    JVM* jvm = (JVM*)malloc(sizeof(JVM));
    if (!jvm) {
        return NULL;
    }
    
    /* Initialize stack */
    jvm->sp = 0;
    jvm->fp = 0;
    jvm->heap_ptr = 0;
    jvm->debug = 0;  /* Debug mode off by default */
    
    /* Clear memory */
    memset(jvm->stack, 0, sizeof(jvm->stack));
    memset(jvm->frames, 0, sizeof(jvm->frames));
    memset(jvm->heap, 0, sizeof(jvm->heap));
    
    return jvm;
}

/* Destroy JVM instance */
void jvm_destroy(JVM* jvm) {
    if (jvm) {
        free(jvm);
    }
}

/* Push value onto operand stack */
void jvm_push(JVM* jvm, Value value) {
    if (jvm->sp >= STACK_SIZE) {
        printf("Stack overflow!\n");
        exit(1);
    }
    jvm->stack[jvm->sp++] = value;
}

/* Pop value from operand stack */
Value jvm_pop(JVM* jvm) {
    if (jvm->sp <= 0) {
        printf("Stack underflow!\n");
        exit(1);
    }
    return jvm->stack[--jvm->sp];
}

/* Read 16-bit signed integer from bytecode */
int16_t read_int16(uint8_t* code, int* pc) {
    int16_t value = (int16_t)((code[*pc] << 8) | code[*pc + 1]);
    *pc += 2;
    return value;
}

/* Read 32-bit signed integer from bytecode */
int32_t read_int32(uint8_t* code, int* pc) {
    int32_t value = (int32_t)((code[*pc] << 24) | (code[*pc + 1] << 16) | 
                              (code[*pc + 2] << 8) | code[*pc + 3]);
    *pc += 4;
    return value;
}

/* Print current stack state for debugging */
void jvm_print_stack(JVM* jvm) {
    printf("Stack (sp=%d): [", jvm->sp);
    for (int i = 0; i < jvm->sp; i++) {
        printf("%d", jvm->stack[i].i);
        if (i < jvm->sp - 1) printf(", ");
    }
    printf("]\n");
}

/* Enable/disable debug mode */
void jvm_set_debug(JVM* jvm, int debug) {
    jvm->debug = debug;
}

/* Main execution loop */
int jvm_execute(JVM* jvm, uint8_t* bytecode, int length) {
    Frame* frame = &jvm->frames[jvm->fp];
    frame->code = bytecode;
    frame->code_length = length;
    frame->pc = 0;
    frame->locals_count = LOCALS_SIZE;
    
    /* Allocate local variables array */
    frame->locals = (Value*)malloc(sizeof(Value) * LOCALS_SIZE);
    if (!frame->locals) {
        printf("Failed to allocate locals\n");
        return -1;
    }
    memset(frame->locals, 0, sizeof(Value) * LOCALS_SIZE);
    
    /* Main execution loop */
    while (frame->pc < frame->code_length) {
        uint8_t opcode = frame->code[frame->pc++];
        
        switch (opcode) {
            case OP_NOP:
                /* No operation */
                break;
                
            case OP_ICONST_M1: {
                Value v = {-1};
                jvm_push(jvm, v);
                break;
            }
            
            case OP_ICONST_0: {
                Value v = {0};
                jvm_push(jvm, v);
                break;
            }
            
            case OP_ICONST_1: {
                Value v = {1};
                jvm_push(jvm, v);
                break;
            }
            
            case OP_ICONST_2: {
                Value v = {2};
                jvm_push(jvm, v);
                break;
            }
            
            case OP_ICONST_3: {
                Value v = {3};
                jvm_push(jvm, v);
                break;
            }
            
            case OP_ICONST_4: {
                Value v = {4};
                jvm_push(jvm, v);
                break;
            }
            
            case OP_ICONST_5: {
                Value v = {5};
                jvm_push(jvm, v);
                break;
            }
            
            case OP_BIPUSH: {
                int8_t byte_val = (int8_t)frame->code[frame->pc++];
                Value v = {(int32_t)byte_val};
                jvm_push(jvm, v);
                break;
            }
            
            case OP_SIPUSH: {
                int16_t short_val = read_int16(frame->code, &frame->pc);
                Value v = {(int32_t)short_val};
                jvm_push(jvm, v);
                break;
            }
            
            case OP_ILOAD: {
                uint8_t index = frame->code[frame->pc++];
                jvm_push(jvm, frame->locals[index]);
                break;
            }
            
            case OP_ILOAD_0:
                jvm_push(jvm, frame->locals[0]);
                break;
                
            case OP_ILOAD_1:
                jvm_push(jvm, frame->locals[1]);
                break;
                
            case OP_ILOAD_2:
                jvm_push(jvm, frame->locals[2]);
                break;
                
            case OP_ILOAD_3:
                jvm_push(jvm, frame->locals[3]);
                break;
                
            case OP_ISTORE: {
                uint8_t index = frame->code[frame->pc++];
                frame->locals[index] = jvm_pop(jvm);
                break;
            }
            
            case OP_ISTORE_0:
                frame->locals[0] = jvm_pop(jvm);
                break;
                
            case OP_ISTORE_1:
                frame->locals[1] = jvm_pop(jvm);
                break;
                
            case OP_ISTORE_2:
                frame->locals[2] = jvm_pop(jvm);
                break;
                
            case OP_ISTORE_3:
                frame->locals[3] = jvm_pop(jvm);
                break;
                
            case OP_IADD: {
                Value b = jvm_pop(jvm);
                Value a = jvm_pop(jvm);
                Value result = {a.i + b.i};
                jvm_push(jvm, result);
                break;
            }
            
            case OP_ISUB: {
                Value b = jvm_pop(jvm);
                Value a = jvm_pop(jvm);
                Value result = {a.i - b.i};
                jvm_push(jvm, result);
                break;
            }
            
            case OP_IMUL: {
                Value b = jvm_pop(jvm);
                Value a = jvm_pop(jvm);
                Value result = {a.i * b.i};
                jvm_push(jvm, result);
                break;
            }
            
            case OP_IDIV: {
                Value b = jvm_pop(jvm);
                Value a = jvm_pop(jvm);
                if (b.i == 0) {
                    printf("Division by zero!\n");
                    free(frame->locals);
                    return -1;
                }
                Value result = {a.i / b.i};
                jvm_push(jvm, result);
                break;
            }
            
            case OP_IREM: {
                Value b = jvm_pop(jvm);
                Value a = jvm_pop(jvm);
                if (b.i == 0) {
                    printf("Division by zero!\n");
                    free(frame->locals);
                    return -1;
                }
                Value result = {a.i % b.i};
                jvm_push(jvm, result);
                break;
            }
            
            case OP_INEG: {
                Value a = jvm_pop(jvm);
                Value result = {-a.i};
                jvm_push(jvm, result);
                break;
            }
            
            case OP_IF_ICMPEQ: {
                int16_t offset = read_int16(frame->code, &frame->pc);
                Value b = jvm_pop(jvm);
                Value a = jvm_pop(jvm);
                if (a.i == b.i) {
                    frame->pc += offset - 3; /* -3 because we already advanced pc */
                }
                break;
            }
            
            case OP_IF_ICMPNE: {
                int16_t offset = read_int16(frame->code, &frame->pc);
                Value b = jvm_pop(jvm);
                Value a = jvm_pop(jvm);
                if (a.i != b.i) {
                    frame->pc += offset - 3;
                }
                break;
            }
            
            case OP_IF_ICMPLT: {
                int16_t offset = read_int16(frame->code, &frame->pc);
                Value b = jvm_pop(jvm);
                Value a = jvm_pop(jvm);
                if (a.i < b.i) {
                    frame->pc += offset - 3;
                }
                break;
            }
            
            case OP_IF_ICMPGE: {
                int16_t offset = read_int16(frame->code, &frame->pc);
                Value b = jvm_pop(jvm);
                Value a = jvm_pop(jvm);
                if (a.i >= b.i) {
                    frame->pc += offset - 3;
                }
                break;
            }
            
            case OP_IF_ICMPGT: {
                int16_t offset = read_int16(frame->code, &frame->pc);
                Value b = jvm_pop(jvm);
                Value a = jvm_pop(jvm);
                if (a.i > b.i) {
                    frame->pc += offset - 3;
                }
                break;
            }
            
            case OP_IF_ICMPLE: {
                int16_t offset = read_int16(frame->code, &frame->pc);
                Value b = jvm_pop(jvm);
                Value a = jvm_pop(jvm);
                if (a.i <= b.i) {
                    frame->pc += offset - 3;
                }
                break;
            }
            
            case OP_GOTO: {
                int16_t offset = read_int16(frame->code, &frame->pc);
                frame->pc += offset - 3;
                break;
            }
            
            case OP_IRETURN: {
                Value result = jvm_pop(jvm);
                free(frame->locals);
                printf("Method returned: %d\n", result.i);
                return result.i;
            }
            
            case OP_RETURN:
                free(frame->locals);
                printf("Method returned (void)\n");
                return 0;
                
            case OP_HALT:
                free(frame->locals);
                printf("Execution halted\n");
                return 0;
                
            default:
                printf("Unknown opcode: 0x%02x at pc=%d\n", opcode, frame->pc - 1);
                free(frame->locals);
                return -1;
        }
    }
    
    free(frame->locals);
    printf("Reached end of bytecode\n");
    return 0;
}
