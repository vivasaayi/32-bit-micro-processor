#ifndef JVM_H
#define JVM_H

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>

/* Basic JVM constants */
#define STACK_SIZE 1024
#define LOCALS_SIZE 256
#define HEAP_SIZE 8192
#define MAX_METHODS 64
#define MAX_CLASSES 32

/* Basic Java bytecode opcodes - starting with essentials */
typedef enum {
    OP_NOP          = 0x00,
    OP_ICONST_M1    = 0x02,
    OP_ICONST_0     = 0x03,
    OP_ICONST_1     = 0x04,
    OP_ICONST_2     = 0x05,
    OP_ICONST_3     = 0x06,
    OP_ICONST_4     = 0x07,
    OP_ICONST_5     = 0x08,
    OP_BIPUSH       = 0x10,
    OP_SIPUSH       = 0x11,
    OP_ILOAD        = 0x15,
    OP_ILOAD_0      = 0x1a,
    OP_ILOAD_1      = 0x1b,
    OP_ILOAD_2      = 0x1c,
    OP_ILOAD_3      = 0x1d,
    OP_ISTORE       = 0x36,
    OP_ISTORE_0     = 0x3b,
    OP_ISTORE_1     = 0x3c,
    OP_ISTORE_2     = 0x3d,
    OP_ISTORE_3     = 0x3e,
    OP_IADD         = 0x60,
    OP_ISUB         = 0x64,
    OP_IMUL         = 0x68,
    OP_IDIV         = 0x6c,
    OP_IREM         = 0x70,
    OP_INEG         = 0x74,
    OP_IF_ICMPEQ    = 0x9f,
    OP_IF_ICMPNE    = 0xa0,
    OP_IF_ICMPLT    = 0xa1,
    OP_IF_ICMPGE    = 0xa2,
    OP_IF_ICMPGT    = 0xa3,
    OP_IF_ICMPLE    = 0xa4,
    OP_GOTO         = 0xa7,
    OP_IRETURN      = 0xac,
    OP_RETURN       = 0xb1,
    OP_INVOKESTATIC = 0xb8,
    OP_HALT         = 0xff  /* Custom opcode for stopping execution */
} Opcode;

/* JVM value types */
typedef struct {
    int32_t i;
} Value;

/* Stack frame */
typedef struct {
    Value* locals;      /* Local variables */
    uint8_t* code;      /* Method bytecode */
    int pc;             /* Program counter */
    int locals_count;   /* Number of local variables */
    int code_length;    /* Length of bytecode */
} Frame;

/* JVM runtime */
typedef struct {
    Value stack[STACK_SIZE];    /* Operand stack */
    int sp;                     /* Stack pointer */
    Frame frames[256];          /* Call stack */
    int fp;                     /* Frame pointer */
    uint8_t heap[HEAP_SIZE];    /* Simple heap */
    int heap_ptr;               /* Heap allocation pointer */
    int debug;                  /* Debug mode flag */
} JVM;

/* Method descriptor */
typedef struct {
    char* name;
    uint8_t* code;
    int code_length;
    int locals_count;
} Method;

/* Class descriptor */
typedef struct {
    char* name;
    Method methods[MAX_METHODS];
    int method_count;
} Class;

/* Function declarations */
JVM* jvm_create(void);
void jvm_destroy(JVM* jvm);
int jvm_execute(JVM* jvm, uint8_t* bytecode, int length);
void jvm_push(JVM* jvm, Value value);
Value jvm_pop(JVM* jvm);
void jvm_print_stack(JVM* jvm);
void jvm_set_debug(JVM* jvm, int debug);  /* Enable/disable debug mode */

/* Utility functions */
int16_t read_int16(uint8_t* code, int* pc);
int32_t read_int32(uint8_t* code, int* pc);

#endif
