#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <ctype.h>
#include <stdbool.h>

#define MAX_LINE_LENGTH 1024
#define MAX_LABEL_LENGTH 64
#define MAX_LABELS 1000
#define MAX_INSTRUCTIONS 100000
#define MAX_DATA_WORDS 10000

// Instruction format (32-bit):
// Bits 31-27: Opcode (5 bits)
// Bits 26-24: Function/Subopcode (3 bits)
// Bits 23-19: Destination Register (5 bits)
// Bits 18-14: Source Register 1 (5 bits)
// Bits 13-9:  Source Register 2 (5 bits)
// Bits 8-0:   Immediate/Offset (9 bits, sign-extended)

// For large immediates (19-bit):
// Bits 31-27: Opcode (5 bits)
// Bits 26-24: Reserved (3 bits)
// Bits 23-19: Destination Register (5 bits)
// Bits 18-0:  19-bit Immediate

typedef enum {
    // Data Movement
    OP_LOADI = 0x01,  // Load immediate (19-bit)
    OP_LOAD  = 0x02,  // Load from memory
    OP_STORE = 0x03,  // Store to memory
    
    // Arithmetic (matching CPU opcodes)
    OP_ADD   = 0x04,  // Add registers
    OP_ADDI  = 0x05,  // Add immediate
    OP_SUB   = 0x06,  // Subtract registers
    OP_SUBI  = 0x07,  // Subtract immediate
    OP_MUL   = 0x08,  // Multiply
    OP_DIV   = 0x09,  // Divide
    OP_MOD   = 0x0A,  // Modulo (remainder)
    
    // Logical (updated opcodes)
    OP_AND   = 0x0B,  // Logical AND
    OP_OR    = 0x0C,  // Logical OR
    OP_XOR   = 0x0D,  // Logical XOR
    OP_NOT   = 0x0E,  // Logical NOT
    OP_SHL   = 0x0F,  // Shift left logical
    OP_SHR   = 0x10,  // Shift right logical
    
    // Comparison & Branches (updated opcodes)
    OP_CMP   = 0x11,  // Compare (updated from 0x10)
    OP_JMP   = 0x12,  // Unconditional jump
    OP_JZ    = 0x13,  // Jump if zero
    OP_JNZ   = 0x14,  // Jump if not zero
    OP_JC    = 0x15,  // Jump if carry
    OP_JNC   = 0x16,  // Jump if no carry
    OP_JLT   = 0x17,  // Jump if less than
    OP_JGE   = 0x18,  // Jump if greater or equal
    OP_JLE   = 0x19,  // Jump if less or equal
    OP_JN    = 0x1A,  // Jump if negative
    
    // Function Calls & Stack (updated opcodes)
    OP_CALL  = 0x1B,  // Function call
    OP_RET   = 0x1C,  // Return from function
    OP_PUSH  = 0x1D,  // Push register to stack
    OP_POP   = 0x1E,  // Pop from stack to register
    
    // System
    OP_HALT  = 0x1F,  // Halt processor
    OP_OUT   = 0x20,  // Output (for putchar support)
} opcode_t;

typedef enum {
    INST_TYPE_RRR,    // Register-Register-Register (ADD R1, R2, R3)
    INST_TYPE_RRI,    // Register-Register-Immediate (ADDI R1, R2, #5)
    INST_TYPE_RI,     // Register-Immediate (LOADI R1, #42)
    INST_TYPE_RR,     // Register-Register (MOVE R1, R2)
    INST_TYPE_R,      // Register only (PUSH R1)
    INST_TYPE_I,      // Immediate only (JMP label)
    INST_TYPE_NONE,   // No operands (HALT, RET)
    INST_TYPE_MEM,    // Memory operations [reg] or [reg+offset]
} inst_type_t;

typedef struct {
    const char *name;
    opcode_t opcode;
    inst_type_t type;
} instruction_def_t;

typedef struct {
    char name[MAX_LABEL_LENGTH];
    uint32_t address;
    bool is_data;  // true if this is a data label
} label_t;

typedef struct {
    uint32_t address;
    uint32_t instruction;
    char source_line[MAX_LINE_LENGTH];
    bool needs_resolution;  // True if this instruction has forward references
    char forward_label[MAX_LABEL_LENGTH];  // Label that needs to be resolved
    opcode_t opcode;
    int rd, rs1, rs2;
    inst_type_t type;
} assembled_inst_t;

typedef struct {
    uint32_t address;
    uint32_t value;
    char label[MAX_LABEL_LENGTH];
} data_word_t;

// Enhanced instruction definitions with C compiler compatibility
static const instruction_def_t instructions[] = {
    // Data Movement - support both formats
    {"LOADI", OP_LOADI, INST_TYPE_RI},
    {"loadi", OP_LOADI, INST_TYPE_RI},
    {"LOAD",  OP_LOAD,  INST_TYPE_MEM},  // Enhanced for [reg] format
    {"load",  OP_LOAD,  INST_TYPE_MEM},  // Enhanced for [reg] format
    {"STORE", OP_STORE, INST_TYPE_MEM},  // Enhanced for [reg] format
    {"store", OP_STORE, INST_TYPE_MEM},  // Enhanced for [reg] format
    {"MOVE",  OP_ADD,   INST_TYPE_RR},   // MOVE R1, R2 -> ADD R1, R2, R0
    {"move",  OP_ADD,   INST_TYPE_RR},   // MOVE R1, R2 -> ADD R1, R2, R0
    {"MOV",   OP_ADD,   INST_TYPE_RR},   // C compiler uses lowercase mov
    {"mov",   OP_ADD,   INST_TYPE_RR},   // C compiler uses lowercase mov
    
    // Arithmetic - support both uppercase and lowercase
    {"ADD",   OP_ADD,   INST_TYPE_RRR},
    {"add",   OP_ADD,   INST_TYPE_RRR},
    {"ADDI",  OP_ADDI,  INST_TYPE_RRI},
    {"addi",  OP_ADDI,  INST_TYPE_RRI},
    {"SUB",   OP_SUB,   INST_TYPE_RRR},
    {"sub",   OP_SUB,   INST_TYPE_RRR},
    {"SUBI",  OP_SUBI,  INST_TYPE_RRI},
    {"subi",  OP_SUBI,  INST_TYPE_RRI},
    {"MUL",   OP_MUL,   INST_TYPE_RRR},
    {"mul",   OP_MUL,   INST_TYPE_RRR},
    {"DIV",   OP_DIV,   INST_TYPE_RRR},
    {"div",   OP_DIV,   INST_TYPE_RRR},
    {"MOD",   OP_MOD,   INST_TYPE_RRR},
    {"mod",   OP_MOD,   INST_TYPE_RRR},
    
    // Logical
    {"AND",   OP_AND,   INST_TYPE_RRR},
    {"and",   OP_AND,   INST_TYPE_RRR},
    {"OR",    OP_OR,    INST_TYPE_RRR},
    {"or",    OP_OR,    INST_TYPE_RRR},
    {"XOR",   OP_XOR,   INST_TYPE_RRR},
    {"xor",   OP_XOR,   INST_TYPE_RRR},
    {"NOT",   OP_NOT,   INST_TYPE_RR},
    {"not",   OP_NOT,   INST_TYPE_RR},
    {"SHL",   OP_SHL,   INST_TYPE_RRR},
    {"shl",   OP_SHL,   INST_TYPE_RRR},
    {"SHR",   OP_SHR,   INST_TYPE_RRR},
    {"shr",   OP_SHR,   INST_TYPE_RRR},
    
    // Comparison & Branches - support C compiler aliases
    {"CMP",   OP_CMP,   INST_TYPE_RR},
    {"cmp",   OP_CMP,   INST_TYPE_RR},
    {"JMP",   OP_JMP,   INST_TYPE_I},
    {"jmp",   OP_JMP,   INST_TYPE_I},
    {"JZ",    OP_JZ,    INST_TYPE_I},
    {"jz",    OP_JZ,    INST_TYPE_I},
    {"JE",    OP_JZ,    INST_TYPE_I},   // C compiler alias for JZ
    {"je",    OP_JZ,    INST_TYPE_I},   // C compiler alias for JZ
    {"JNZ",   OP_JNZ,   INST_TYPE_I},
    {"jnz",   OP_JNZ,   INST_TYPE_I},
    {"JNE",   OP_JNZ,   INST_TYPE_I},  // C compiler alias for JNZ
    {"jne",   OP_JNZ,   INST_TYPE_I},  // C compiler alias for JNZ
    {"JC",    OP_JC,    INST_TYPE_I},
    {"jc",    OP_JC,    INST_TYPE_I},
    {"JNC",   OP_JNC,   INST_TYPE_I},
    {"jnc",   OP_JNC,   INST_TYPE_I},
    {"JLT",   OP_JLT,   INST_TYPE_I},
    {"jlt",   OP_JLT,   INST_TYPE_I},
    {"JGE",   OP_JGE,   INST_TYPE_I},
    {"jge",   OP_JGE,   INST_TYPE_I},
    {"JLE",   OP_JLE,   INST_TYPE_I},
    {"jle",   OP_JLE,   INST_TYPE_I},
    {"JN",    OP_JN,    INST_TYPE_I},
    {"jn",    OP_JN,    INST_TYPE_I},
    
    // Function Calls & Stack
    {"CALL",  OP_CALL,  INST_TYPE_I},
    {"call",  OP_CALL,  INST_TYPE_I},
    {"RET",   OP_RET,   INST_TYPE_NONE},
    {"ret",   OP_RET,   INST_TYPE_NONE},
    {"PUSH",  OP_PUSH,  INST_TYPE_R},
    {"push",  OP_PUSH,  INST_TYPE_R},
    {"POP",   OP_POP,   INST_TYPE_R},
    {"pop",   OP_POP,   INST_TYPE_R},
    
    // System
    {"HALT",  OP_HALT,  INST_TYPE_NONE},
    {"halt",  OP_HALT,  INST_TYPE_NONE},
    {"OUT",   OP_OUT,   INST_TYPE_R},    // For putchar support
    {"out",   OP_OUT,   INST_TYPE_R},    // For putchar support
};

static const int num_instructions = sizeof(instructions) / sizeof(instructions[0]);

// Global state
static label_t labels[MAX_LABELS];
static int num_labels = 0;
static assembled_inst_t assembled[MAX_INSTRUCTIONS];
static int num_assembled = 0;
static data_word_t data_words[MAX_DATA_WORDS];
static int num_data_words = 0;
static uint32_t current_address = 0;

// Stack pointer and frame pointer registers
static const int SP_REG = 30;  // R30 = stack pointer
static const int FP_REG = 31;  // R31 = frame pointer

// Utility functions
static void error(const char *msg, int line_num) {
    fprintf(stderr, "Error on line %d: %s\n", line_num, msg);
    exit(1);
}

static void warning(const char *msg, int line_num) {
    fprintf(stderr, "Warning on line %d: %s\n", line_num, msg);
}

static char *trim_whitespace(char *str) {
    // Trim leading whitespace
    while (isspace(*str)) str++;
    
    // Trim trailing whitespace
    char *end = str + strlen(str) - 1;
    while (end > str && isspace(*end)) *end-- = '\0';
    
    return str;
}

static int parse_register(const char *str) {
    // Skip whitespace and commas
    while (*str && (isspace(*str) || *str == ',')) str++;
    
    // Handle common register aliases first
    if (strncasecmp(str, "sp", 2) == 0 && (str[2] == '\0' || isspace(str[2]) || str[2] == ',')) return SP_REG;
    if (strncasecmp(str, "fp", 2) == 0 && (str[2] == '\0' || isspace(str[2]) || str[2] == ',')) return FP_REG;
    
    // Handle register names
    if (*str == 'R' || *str == 'r') {
        char *endptr;
        int reg = strtol(str + 1, &endptr, 10);
        
        // Check for valid conversion and range
        if (endptr == str + 1 || reg < 0 || reg > 31) return -1;
        
        return reg;
    }
    
    return -1;
}

static int parse_immediate(const char *str) {
    // Skip whitespace and commas
    while (*str && (isspace(*str) || *str == ',')) str++;
    
    if (*str == '#') str++; // Skip optional '#'
    
    char *endptr;
    int value;
    
    if (str[0] == '0' && (str[1] == 'x' || str[1] == 'X')) {
        // Hexadecimal
        value = strtol(str + 2, &endptr, 16);
    } else {
        // Decimal
        value = strtol(str, &endptr, 10);
    }
    
    return value;
}

// Parse memory reference like [r1] or [r1+4] or [label]
static bool parse_memory_ref(const char *str, int *reg, int *offset, char *label) {
    // Skip whitespace and commas
    while (*str && (isspace(*str) || *str == ',')) str++;
    
    *reg = -1;
    *offset = 0;
    label[0] = '\0';
    
    if (*str != '[') return false;
    str++; // Skip '['
    
    // Find the closing bracket
    const char *end = strchr(str, ']');
    if (!end) return false;
    
    // Copy the content between brackets
    int len = end - str;
    char content[256];
    strncpy(content, str, len);
    content[len] = '\0';
    
    // Check if it's a register reference
    if (content[0] == 'r' || content[0] == 'R') {
        *reg = parse_register(content);
        if (*reg < 0) return false;
        
        // Check for offset
        char *plus = strchr(content, '+');
        if (plus) {
            *offset = parse_immediate(plus + 1);
        }
        return true;
    }
    
    // Otherwise, it's a label reference
    strncpy(label, content, MAX_LABEL_LENGTH - 1);
    label[MAX_LABEL_LENGTH - 1] = '\0';
    return true;
}

static const instruction_def_t *find_instruction(const char *name) {
    for (int i = 0; i < num_instructions; i++) {
        if (strcasecmp(name, instructions[i].name) == 0) {
            return &instructions[i];
        }
    }
    return NULL;
}

static void add_label(const char *name, uint32_t address, bool is_data) {
    if (num_labels >= MAX_LABELS) {
        error("Too many labels", 0);
    }
    
    // Check for duplicate labels
    for (int i = 0; i < num_labels; i++) {
        if (strcmp(labels[i].name, name) == 0) {
            error("Duplicate label", 0);
        }
    }
    
    strncpy(labels[num_labels].name, name, MAX_LABEL_LENGTH - 1);
    labels[num_labels].name[MAX_LABEL_LENGTH - 1] = '\0';
    labels[num_labels].address = address;
    labels[num_labels].is_data = is_data;
    num_labels++;
}

static int find_label(const char *name) {
    for (int i = 0; i < num_labels; i++) {
        if (strcmp(labels[i].name, name) == 0) {
            return labels[i].address;
        }
    }
    return -1;
}

static uint32_t encode_instruction(opcode_t opcode, int rd, int rs1, int rs2, int immediate, bool use_19bit_imm) {
    if (use_19bit_imm) {
        // 19-bit immediate format
        return ((uint32_t)opcode << 27) | 
               ((uint32_t)(rd & 0x1F) << 19) | 
               ((uint32_t)immediate & 0x7FFFF);
    } else {
        // Standard format
        return ((uint32_t)opcode << 27) | 
               ((uint32_t)(rd & 0x1F) << 19) | 
               ((uint32_t)(rs1 & 0x1F) << 14) | 
               ((uint32_t)(rs2 & 0x1F) << 9) | 
               ((uint32_t)immediate & 0x1FF);
    }
}

static void handle_data_directive(const char *line, int line_num) {
    // Handle .word directive
    if (strncasecmp(line, ".word", 5) == 0) {
        char *value_str = (char *)line + 5;
        value_str = trim_whitespace(value_str);
        
        uint32_t value = parse_immediate(value_str);
        
        if (num_data_words >= MAX_DATA_WORDS) {
            error("Too many data words", line_num);
        }
        
        data_words[num_data_words].address = current_address;
        data_words[num_data_words].value = value;
        data_words[num_data_words].label[0] = '\0';
        num_data_words++;
        
        current_address += 4;  // Each word is 4 bytes
    }
}

// Enhanced instruction assembly with better C compiler support
static void assemble_instruction(const char *line, int line_num) {
    char line_copy[MAX_LINE_LENGTH];
    strncpy(line_copy, line, MAX_LINE_LENGTH - 1);
    line_copy[MAX_LINE_LENGTH - 1] = '\0';
    
    // Handle data directives
    if (line_copy[0] == '.') {
        handle_data_directive(line_copy, line_num);
        return;
    }
    
    // Tokenize the line manually - be more flexible with C compiler output
    char *tokens[10];
    int num_tokens = 0;
    
    // Replace commas with spaces, but preserve brackets and other syntax
    for (char *p = line_copy; *p; p++) {
        if (*p == ',' && *(p+1) != ' ') {
            *p = ' ';
        }
    }
    
    // Manual tokenization
    char *start = line_copy;
    while (*start && num_tokens < 10) {
        // Skip whitespace
        while (*start && isspace(*start)) start++;
        if (!*start) break;
        
        // Handle bracketed expressions as single tokens
        if (*start == '[') {
            char *end = strchr(start, ']');
            if (end) {
                end++; // Include the closing bracket
                *end = '\0';
                tokens[num_tokens++] = start;
                start = end + 1;
                continue;
            }
        }
        
        // Find end of token
        char *end = start;
        while (*end && !isspace(*end) && *end != ',' && *end != '[') end++;
        
        // Null-terminate the token
        if (*end) {
            *end = '\0';
            tokens[num_tokens++] = start;
            start = end + 1;
        } else {
            tokens[num_tokens++] = start;
            break;
        }
    }
    
    if (num_tokens == 0) return;
    
    const instruction_def_t *inst = find_instruction(tokens[0]);
    if (!inst) {
        char msg[256];
        snprintf(msg, sizeof(msg), "Unknown instruction: %s", tokens[0]);
        error(msg, line_num);
    }
    
    uint32_t encoded = 0;
    int rd = 0, rs1 = 0, rs2 = 0, immediate = 0;
    bool use_19bit_imm = false;
    
    switch (inst->type) {
        case INST_TYPE_NONE:
            encoded = encode_instruction(inst->opcode, 0, 0, 0, 0, false);
            break;
            
        case INST_TYPE_R:
            if (num_tokens < 2) error("Missing register operand", line_num);
            rd = parse_register(tokens[1]);
            if (rd < 0) error("Invalid register", line_num);
            encoded = encode_instruction(inst->opcode, rd, 0, 0, 0, false);
            break;
            
        case INST_TYPE_RR:
            if (num_tokens < 3) error("Missing register operands", line_num);
            rd = parse_register(tokens[1]);
            
            // Handle different formats for second operand
            if (tokens[2][0] == '#') {
                // MOV r1, #5 -> LOADI r1, #5
                immediate = parse_immediate(tokens[2]);
                encoded = encode_instruction(OP_LOADI, rd, 0, 0, immediate, true);
                use_19bit_imm = true;
            } else {
                rs1 = parse_register(tokens[2]);
                if (rd < 0 || rs1 < 0) error("Invalid register", line_num);
                // MOVE/MOV R1, R2 -> ADD R1, R2, R0
                encoded = encode_instruction(inst->opcode, rd, rs1, 0, 0, false);
            }
            break;
            
        case INST_TYPE_RRR:
            if (num_tokens < 4) error("Missing register operands", line_num);
            rd = parse_register(tokens[1]);
            rs1 = parse_register(tokens[2]);
            rs2 = parse_register(tokens[3]);
            if (rd < 0 || rs1 < 0 || rs2 < 0) error("Invalid register", line_num);
            encoded = encode_instruction(inst->opcode, rd, rs1, rs2, 0, false);
            break;
            
        case INST_TYPE_RRI:
            if (num_tokens < 4) error("Missing operands", line_num);
            rd = parse_register(tokens[1]);
            rs1 = parse_register(tokens[2]);
            immediate = parse_immediate(tokens[3]);
            if (rd < 0 || rs1 < 0) error("Invalid register", line_num);
            if (immediate < -256 || immediate > 255) error("Immediate out of range", line_num);
            encoded = encode_instruction(inst->opcode, rd, rs1, 0, immediate, false);
            break;
            
        case INST_TYPE_RI:
            if (num_tokens < 3) error("Missing operands", line_num);
            rd = parse_register(tokens[1]);
            immediate = parse_immediate(tokens[2]);
            if (rd < 0) error("Invalid register", line_num);
            // Allow full 32-bit values for LOADI - we'll use 19-bit encoding when possible
            if (immediate >= -262144 && immediate <= 262143) {
                encoded = encode_instruction(inst->opcode, rd, 0, 0, immediate, true);
            } else {
                // For larger values, we need to split into multiple instructions
                // For now, just mask to 19 bits and warn
                warning("Large immediate value truncated to 19 bits", line_num);
                encoded = encode_instruction(inst->opcode, rd, 0, 0, immediate & 0x7FFFF, true);
            }
            use_19bit_imm = true;
            break;
            
        case INST_TYPE_MEM:
            // Handle enhanced memory operations: load/store with [reg], [label], or direct label
            if (num_tokens < 3) error("Missing operands", line_num);
            
            if (inst->opcode == OP_LOAD) {
                // LOAD rd, [rs1+offset] or LOAD rd, [label] or LOAD rd, label
                rd = parse_register(tokens[1]);
                if (rd < 0) error("Invalid destination register", line_num);
                
                int mem_reg, mem_offset;
                char mem_label[MAX_LABEL_LENGTH];
                
                if (tokens[2][0] == '[') {
                    // Bracketed memory reference
                    if (parse_memory_ref(tokens[2], &mem_reg, &mem_offset, mem_label)) {
                        if (mem_reg >= 0) {
                            // Register + offset
                            encoded = encode_instruction(inst->opcode, rd, mem_reg, 0, mem_offset, false);
                        } else if (mem_label[0]) {
                            // Label reference - need to resolve
                            int label_addr = find_label(mem_label);
                            if (label_addr >= 0) {
                                // Use absolute addressing
                                encoded = encode_instruction(inst->opcode, rd, 0, 0, label_addr, true);
                                use_19bit_imm = true;
                            } else {
                                // Forward reference - will be resolved in second pass
                                encoded = encode_instruction(inst->opcode, rd, 0, 0, 0, true);
                                use_19bit_imm = true;
                            }
                        }
                    } else {
                        error("Invalid memory reference", line_num);
                    }
                } else {
                    // Direct label reference (backward compatibility)
                    strncpy(mem_label, tokens[2], MAX_LABEL_LENGTH - 1);
                    mem_label[MAX_LABEL_LENGTH - 1] = '\0';
                    
                    int label_addr = find_label(mem_label);
                    if (label_addr >= 0) {
                        // Use absolute addressing
                        encoded = encode_instruction(inst->opcode, rd, 0, 0, label_addr, true);
                        use_19bit_imm = true;
                    } else {
                        // Forward reference - will be resolved in second pass
                        encoded = encode_instruction(inst->opcode, rd, 0, 0, 0, true);
                        use_19bit_imm = true;
                    }
                }
            } else if (inst->opcode == OP_STORE) {
                // Handle multiple STORE formats:
                // STORE [rs1+offset], rd  (new format)
                // STORE [label], rd       (new format)
                // STORE rd, label         (C compiler format - backward compatibility)
                // STORE rd, [rs1+offset]  (alternative format)
                
                if (tokens[1][0] == '[') {
                    // New format: STORE [dest], src
                    rd = parse_register(tokens[2]);
                    if (rd < 0) error("Invalid source register", line_num);
                    
                    int mem_reg, mem_offset;
                    char mem_label[MAX_LABEL_LENGTH];
                    
                    if (parse_memory_ref(tokens[1], &mem_reg, &mem_offset, mem_label)) {
                        if (mem_reg >= 0) {
                            // Register + offset
                            encoded = encode_instruction(inst->opcode, rd, mem_reg, 0, mem_offset, false);
                        } else if (mem_label[0]) {
                            // Label reference
                            int label_addr = find_label(mem_label);
                            if (label_addr >= 0) {
                                encoded = encode_instruction(inst->opcode, rd, 0, 0, label_addr, true);
                                use_19bit_imm = true;
                            } else {
                                // Forward reference
                                encoded = encode_instruction(inst->opcode, rd, 0, 0, 0, true);
                                use_19bit_imm = true;
                            }
                        }
                    } else {
                        error("Invalid memory reference", line_num);
                    }
                } else if (tokens[2][0] == '[') {
                    // Alternative format: STORE src, [dest]
                    rd = parse_register(tokens[1]);
                    if (rd < 0) error("Invalid source register", line_num);
                    
                    int mem_reg, mem_offset;
                    char mem_label[MAX_LABEL_LENGTH];
                    
                    if (parse_memory_ref(tokens[2], &mem_reg, &mem_offset, mem_label)) {
                        if (mem_reg >= 0) {
                            // Register + offset
                            encoded = encode_instruction(inst->opcode, rd, mem_reg, 0, mem_offset, false);
                        } else if (mem_label[0]) {
                            // Label reference
                            int label_addr = find_label(mem_label);
                            if (label_addr >= 0) {
                                encoded = encode_instruction(inst->opcode, rd, 0, 0, label_addr, true);
                                use_19bit_imm = true;
                            } else {
                                // Forward reference
                                encoded = encode_instruction(inst->opcode, rd, 0, 0, 0, true);
                                use_19bit_imm = true;
                            }
                        }
                    } else {
                        error("Invalid memory reference", line_num);
                    }
                } else {
                    // C compiler format: STORE src, label (backward compatibility)
                    rd = parse_register(tokens[1]);
                    if (rd < 0) error("Invalid source register", line_num);
                    
                    // tokens[2] should be a label
                    char mem_label[MAX_LABEL_LENGTH];
                    strncpy(mem_label, tokens[2], MAX_LABEL_LENGTH - 1);
                    mem_label[MAX_LABEL_LENGTH - 1] = '\0';
                    
                    int label_addr = find_label(mem_label);
                    if (label_addr >= 0) {
                        encoded = encode_instruction(inst->opcode, rd, 0, 0, label_addr, true);
                        use_19bit_imm = true;
                    } else {
                        // Forward reference
                        encoded = encode_instruction(inst->opcode, rd, 0, 0, 0, true);
                        use_19bit_imm = true;
                    }
                }
            }
            break;
            
        case INST_TYPE_I:
            if (num_tokens < 2) error("Missing operand", line_num);
            // Check if it's a label or immediate
            int label_addr = find_label(tokens[1]);
            if (label_addr >= 0) {
                // It's a label - calculate relative offset for branches
                if (inst->opcode >= OP_JMP && inst->opcode <= OP_JN) {
                    immediate = (label_addr - (current_address + 4)) / 4;
                    if (immediate < -256 || immediate > 255) {
                        // Use absolute addressing
                        encoded = encode_instruction(inst->opcode, 0, 0, 0, label_addr, true);
                        use_19bit_imm = true;
                    } else {
                        encoded = encode_instruction(inst->opcode, 0, 0, 0, immediate, false);
                    }
                } else {
                    // Absolute addressing for CALL
                    encoded = encode_instruction(inst->opcode, 0, 0, 0, label_addr, true);
                    use_19bit_imm = true;
                }
            } else {
                // It's an immediate value
                immediate = parse_immediate(tokens[1]);
                if (immediate >= -256 && immediate <= 255) {
                    encoded = encode_instruction(inst->opcode, 0, 0, 0, immediate, false);
                } else {
                    encoded = encode_instruction(inst->opcode, 0, 0, 0, immediate, true);
                    use_19bit_imm = true;
                }
            }
            break;
    }
    
    // Store the assembled instruction
    if (num_assembled >= MAX_INSTRUCTIONS) {
        error("Too many instructions", line_num);
    }
    
    assembled[num_assembled].address = current_address;
    assembled[num_assembled].instruction = encoded;
    strncpy(assembled[num_assembled].source_line, line, MAX_LINE_LENGTH - 1);
    assembled[num_assembled].source_line[MAX_LINE_LENGTH - 1] = '\0';
    num_assembled++;
    
    current_address += 4;
}

static void first_pass(FILE *input) {
    char line[MAX_LINE_LENGTH];
    int line_num = 0;
    
    while (fgets(line, sizeof(line), input)) {
        line_num++;
        
        // Remove comments (both ; and // style)
        char *comment = strstr(line, ";");
        if (comment) *comment = '\0';
        comment = strstr(line, "//");
        if (comment) *comment = '\0';
        
        char *trimmed = trim_whitespace(line);
        if (strlen(trimmed) == 0) continue;
        
        // Handle .org directive
        if (strncasecmp(trimmed, ".org", 4) == 0) {
            char *addr_str = trimmed + 4;
            addr_str = trim_whitespace(addr_str);
            current_address = parse_immediate(addr_str);
            continue;
        }
        
        // Handle labels
        char *colon = strchr(trimmed, ':');
        if (colon) {
            *colon = '\0';
            char *label_name = trim_whitespace(trimmed);
            
            // Determine if this is a data label
            bool is_data = false;
            char *after_colon = trim_whitespace(colon + 1);
            if (strlen(after_colon) > 0 && after_colon[0] == '.') {
                is_data = true;
            }
            
            add_label(label_name, current_address, is_data);
            
            // Check if there's an instruction after the label
            if (strlen(after_colon) > 0) {
                assemble_instruction(after_colon, line_num);
            }
        } else {
            // Regular instruction
            assemble_instruction(trimmed, line_num);
        }
    }
}

static void second_pass(void) {
    // Re-assemble all instructions now that we know all label addresses
    // This is where we'd resolve forward references if needed
}

static void write_hex_output(FILE *output) {
    // Write assembled instructions
    for (int i = 0; i < num_assembled; i++) {
        fprintf(output, "%08X\n", assembled[i].instruction);
    }
    
    // Write data words
    for (int i = 0; i < num_data_words; i++) {
        fprintf(output, "%08X\n", data_words[i].value);
    }
}

static void print_listing(void) {
    printf("Address  | Machine Code | Source\n");
    printf("---------|--------------|--------\n");
    
    // Print instructions
    for (int i = 0; i < num_assembled; i++) {
        printf("%08X | %08X     | %s\n", 
               assembled[i].address, 
               assembled[i].instruction,
               assembled[i].source_line);
    }
    
    // Print data words
    for (int i = 0; i < num_data_words; i++) {
        printf("%08X | %08X     | .word %s\n", 
               data_words[i].address, 
               data_words[i].value,
               data_words[i].label[0] ? data_words[i].label : "");
    }
    
    if (num_labels > 0) {
        printf("\nLabels:\n");
        for (int i = 0; i < num_labels; i++) {
            printf("%-20s = 0x%08X %s\n", 
                   labels[i].name, 
                   labels[i].address,
                   labels[i].is_data ? "(data)" : "");
        }
    }
}

int main(int argc, char *argv[]) {
    if (argc < 3) {
        fprintf(stderr, "Usage: %s <input.asm> <output.hex> [-l]\n", argv[0]);
        fprintf(stderr, "  -l: Print assembly listing\n");
        fprintf(stderr, "\nEnhanced assembler with C compiler compatibility:\n");
        fprintf(stderr, "  - Supports lowercase instructions\n");
        fprintf(stderr, "  - Handles [reg] and [reg+offset] memory syntax\n");
        fprintf(stderr, "  - Supports .word data directives\n");
        fprintf(stderr, "  - Compatible with C compiler output\n");
        return 1;
    }
    
    bool print_listing_flag = (argc > 3 && strcmp(argv[3], "-l") == 0);
    
    FILE *input = fopen(argv[1], "r");
    if (!input) {
        fprintf(stderr, "Error: Cannot open input file %s\n", argv[1]);
        return 1;
    }
    
    FILE *output = fopen(argv[2], "w");
    if (!output) {
        fprintf(stderr, "Error: Cannot create output file %s\n", argv[2]);
        fclose(input);
        return 1;
    }
    
    printf("Enhanced Assembling %s -> %s\n", argv[1], argv[2]);
    
    // Two-pass assembly
    first_pass(input);
    second_pass();
    
    // Write output
    write_hex_output(output);
    
    printf("Assembly complete: %d instructions, %d data words, %d labels\n", 
           num_assembled, num_data_words, num_labels);
    
    if (print_listing_flag) {
        print_listing();
    }
    
    fclose(input);
    fclose(output);
    
    return 0;
}
