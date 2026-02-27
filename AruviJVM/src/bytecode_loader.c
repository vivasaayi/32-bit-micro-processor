#include "bytecode_loader.h"

#define ARUVIJVM_MAGIC 0xCAFEBABE
#define ARUVIJVM_VERSION 1

/* Load bytecode from file */
int load_bytecode_file(const char* filename, uint8_t** bytecode, int* length) {
    FILE* file = fopen(filename, "rb");
    if (!file) {
        printf("Error: Cannot open file %s\n", filename);
        return -1;
    }
    
    BytecodeHeader header;
    size_t read_size = fread(&header, sizeof(BytecodeHeader), 1, file);
    if (read_size != 1) {
        printf("Error: Cannot read bytecode header\n");
        fclose(file);
        return -1;
    }
    
    /* Verify magic number and version */
    if (header.magic != ARUVIJVM_MAGIC) {
        printf("Error: Invalid magic number. Expected 0x%08x, got 0x%08x\n", 
               ARUVIJVM_MAGIC, header.magic);
        fclose(file);
        return -1;
    }
    
    if (header.version > ARUVIJVM_VERSION) {
        printf("Error: Unsupported version %d (max supported: %d)\n", 
               header.version, ARUVIJVM_VERSION);
        fclose(file);
        return -1;
    }
    
    /* Allocate memory for bytecode */
    *bytecode = (uint8_t*)malloc(header.code_length);
    if (!*bytecode) {
        printf("Error: Cannot allocate memory for bytecode\n");
        fclose(file);
        return -1;
    }
    
    /* Read bytecode */
    read_size = fread(*bytecode, 1, header.code_length, file);
    if (read_size != (size_t)header.code_length) {
        printf("Error: Cannot read bytecode data\n");
        free(*bytecode);
        *bytecode = NULL;
        fclose(file);
        return -1;
    }
    
    *length = header.code_length;
    fclose(file);
    
    printf("Loaded bytecode: %d bytes, version %d\n", *length, header.version);
    return 0;
}

/* Save bytecode to file */
int save_bytecode_file(const char* filename, uint8_t* bytecode, int length) {
    FILE* file = fopen(filename, "wb");
    if (!file) {
        printf("Error: Cannot create file %s\n", filename);
        return -1;
    }
    
    /* Create header */
    BytecodeHeader header;
    header.magic = ARUVIJVM_MAGIC;
    header.version = ARUVIJVM_VERSION;
    header.code_length = length;
    header.entry_point = 0;
    
    /* Write header */
    size_t write_size = fwrite(&header, sizeof(BytecodeHeader), 1, file);
    if (write_size != 1) {
        printf("Error: Cannot write bytecode header\n");
        fclose(file);
        return -1;
    }
    
    /* Write bytecode */
    write_size = fwrite(bytecode, 1, length, file);
    if (write_size != (size_t)length) {
        printf("Error: Cannot write bytecode data\n");
        fclose(file);
        return -1;
    }
    
    fclose(file);
    printf("Saved bytecode: %d bytes to %s\n", length, filename);
    return 0;
}

/* Free bytecode memory */
void free_bytecode(uint8_t* bytecode) {
    if (bytecode) {
        free(bytecode);
    }
}
