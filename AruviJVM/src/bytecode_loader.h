#ifndef BYTECODE_LOADER_H
#define BYTECODE_LOADER_H

#include "jvm.h"

/* Bytecode file header */
typedef struct {
    uint32_t magic;        /* Magic number: 0xCAFEBABE for compatibility */
    uint16_t version;      /* AruviJVM version */
    uint32_t code_length;  /* Length of bytecode */
    uint32_t entry_point;  /* Entry point offset */
} BytecodeHeader;

/* Function declarations */
int load_bytecode_file(const char* filename, uint8_t** bytecode, int* length);
int save_bytecode_file(const char* filename, uint8_t* bytecode, int length);
void free_bytecode(uint8_t* bytecode);

#endif
