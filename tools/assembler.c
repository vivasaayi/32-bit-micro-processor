#include <ctype.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define MAX_LINE_LENGTH 1024
#define MAX_LABEL_LENGTH 64
#define MAX_LABELS 1000
#define MAX_INSTRUCTIONS 100000
#define MAX_DATA_WORDS 10000

// RISC-V Instruction Formats:
// R-type: opcode[6:0], rd[11:7], funct3[14:12], rs1[19:15], rs2[24:20],
// funct7[31:25] I-type: opcode[6:0], rd[11:7], funct3[14:12], rs1[19:15],
// imm[31:20] S-type: opcode[6:0], imm[4:0], funct3[14:12], rs1[19:15],
// rs2[24:20], imm[31:25] B-type: opcode[6:0], imm[11], imm[4:1], funct3[14:12],
// rs1[19:15], rs2[24:20], imm[10:5], imm[12] U-type: opcode[6:0], rd[11:7],
// imm[31:12] J-type: opcode[6:0], rd[11:7], imm[19:12], imm[11], imm[10:1],
// imm[20]

typedef enum {
  OP_LUI = 0x37,
  OP_AUIPC = 0x17,
  OP_JAL = 0x6F,
  OP_JALR = 0x67,
  OP_BRANCH = 0x63,
  OP_LOAD = 0x03,
  OP_STORE = 0x23,
  OP_IMM = 0x13,
  OP_REG = 0x33,
  OP_SYSTEM = 0x73,
  OP_CUSTOM_HALT = 0x73 // EBREAK
} opcode_t;

typedef enum {
  RV_TYPE_R,
  RV_TYPE_I,
  RV_TYPE_S,
  RV_TYPE_B,
  RV_TYPE_U,
  RV_TYPE_J,
  RV_PSEUDO
} inst_type_t;

typedef struct {
  const char *name;
  opcode_t opcode;
  uint8_t funct3;
  uint8_t funct7;
  inst_type_t type;
} instruction_def_t;

typedef struct {
  char name[MAX_LABEL_LENGTH];
  uint32_t address;
  bool is_data; // true if this is a data label
} label_t;

typedef struct {
  uint32_t address;
  uint32_t instruction;
  char source_line[MAX_LINE_LENGTH];
  bool needs_resolution; // True if this instruction has forward references
  char forward_label[MAX_LABEL_LENGTH]; // Label that needs to be resolved
  opcode_t opcode;
  uint8_t funct3;
  uint8_t funct7;
  int rd, rs1, rs2, imm;
  inst_type_t type;
} assembled_inst_t;

typedef struct {
  uint32_t address;
  uint32_t value;
  char label[MAX_LABEL_LENGTH];
} data_word_t;

// Enhanced instruction definitions with C compiler compatibility
static const instruction_def_t instructions[] = {
    // RV32I Base Instruction Set
    {"LUI", OP_LUI, 0, 0, RV_TYPE_U},
    {"lui", OP_LUI, 0, 0, RV_TYPE_U},
    {"AUIPC", OP_AUIPC, 0, 0, RV_TYPE_U},
    {"auipc", OP_AUIPC, 0, 0, RV_TYPE_U},
    {"JAL", OP_JAL, 0, 0, RV_TYPE_J},
    {"jal", OP_JAL, 0, 0, RV_TYPE_J},
    {"JALR", OP_JALR, 0, 0, RV_TYPE_I},
    {"jalr", OP_JALR, 0, 0, RV_TYPE_I},

    // Branch
    {"BEQ", OP_BRANCH, 0, 0, RV_TYPE_B},
    {"beq", OP_BRANCH, 0, 0, RV_TYPE_B},
    {"BNE", OP_BRANCH, 1, 0, RV_TYPE_B},
    {"bne", OP_BRANCH, 1, 0, RV_TYPE_B},
    {"BLT", OP_BRANCH, 4, 0, RV_TYPE_B},
    {"blt", OP_BRANCH, 4, 0, RV_TYPE_B},
    {"BGE", OP_BRANCH, 5, 0, RV_TYPE_B},
    {"bge", OP_BRANCH, 5, 0, RV_TYPE_B},
    {"BLTU", OP_BRANCH, 6, 0, RV_TYPE_B},
    {"bltu", OP_BRANCH, 6, 0, RV_TYPE_B},
    {"BGEU", OP_BRANCH, 7, 0, RV_TYPE_B},
    {"bgeu", OP_BRANCH, 7, 0, RV_TYPE_B},

    // Load
    {"LB", OP_LOAD, 0, 0, RV_TYPE_I},
    {"lb", OP_LOAD, 0, 0, RV_TYPE_I},
    {"LH", OP_LOAD, 1, 0, RV_TYPE_I},
    {"lh", OP_LOAD, 1, 0, RV_TYPE_I},
    {"LW", OP_LOAD, 2, 0, RV_TYPE_I},
    {"lw", OP_LOAD, 2, 0, RV_TYPE_I},
    {"LBU", OP_LOAD, 4, 0, RV_TYPE_I},
    {"lbu", OP_LOAD, 4, 0, RV_TYPE_I},
    {"LHU", OP_LOAD, 5, 0, RV_TYPE_I},
    {"lhu", OP_LOAD, 5, 0, RV_TYPE_I},

    // Store
    {"SB", OP_STORE, 0, 0, RV_TYPE_S},
    {"sb", OP_STORE, 0, 0, RV_TYPE_S},
    {"SH", OP_STORE, 1, 0, RV_TYPE_S},
    {"sh", OP_STORE, 1, 0, RV_TYPE_S},
    {"SW", OP_STORE, 2, 0, RV_TYPE_S},
    {"sw", OP_STORE, 2, 0, RV_TYPE_S},

    // Arithmetic Immediate
    {"ADDI", OP_IMM, 0, 0, RV_TYPE_I},
    {"addi", OP_IMM, 0, 0, RV_TYPE_I},
    {"SLTI", OP_IMM, 2, 0, RV_TYPE_I},
    {"slti", OP_IMM, 2, 0, RV_TYPE_I},
    {"SLTIU", OP_IMM, 3, 0, RV_TYPE_I},
    {"sltiu", OP_IMM, 3, 0, RV_TYPE_I},
    {"XORI", OP_IMM, 4, 0, RV_TYPE_I},
    {"xori", OP_IMM, 4, 0, RV_TYPE_I},
    {"ORI", OP_IMM, 6, 0, RV_TYPE_I},
    {"ori", OP_IMM, 6, 0, RV_TYPE_I},
    {"ANDI", OP_IMM, 7, 0, RV_TYPE_I},
    {"andi", OP_IMM, 7, 0, RV_TYPE_I},
    {"SLLI", OP_IMM, 1, 0, RV_TYPE_I},
    {"slli", OP_IMM, 1, 0, RV_TYPE_I},
    {"SRLI", OP_IMM, 5, 0, RV_TYPE_I},
    {"srli", OP_IMM, 5, 0, RV_TYPE_I},
    {"SRAI", OP_IMM, 5, 0x20, RV_TYPE_I},
    {"srai", OP_IMM, 5, 0x20, RV_TYPE_I},

    // Arithmetic Register
    {"ADD", OP_REG, 0, 0x00, RV_TYPE_R},
    {"add", OP_REG, 0, 0x00, RV_TYPE_R},
    {"SUB", OP_REG, 0, 0x20, RV_TYPE_R},
    {"sub", OP_REG, 0, 0x20, RV_TYPE_R},
    {"SLL", OP_REG, 1, 0x00, RV_TYPE_R},
    {"sll", OP_REG, 1, 0x00, RV_TYPE_R},
    {"SLT", OP_REG, 2, 0x00, RV_TYPE_R},
    {"slt", OP_REG, 2, 0x00, RV_TYPE_R},
    {"SLTU", OP_REG, 3, 0x00, RV_TYPE_R},
    {"sltu", OP_REG, 3, 0x00, RV_TYPE_R},
    {"XOR", OP_REG, 4, 0x00, RV_TYPE_R},
    {"xor", OP_REG, 4, 0x00, RV_TYPE_R},
    {"SRL", OP_REG, 5, 0x00, RV_TYPE_R},
    {"srl", OP_REG, 5, 0x00, RV_TYPE_R},
    {"SRA", OP_REG, 5, 0x20, RV_TYPE_R},
    {"sra", OP_REG, 5, 0x20, RV_TYPE_R},
    {"OR", OP_REG, 6, 0x00, RV_TYPE_R},
    {"or", OP_REG, 6, 0x00, RV_TYPE_R},
    {"AND", OP_REG, 7, 0x00, RV_TYPE_R},
    {"and", OP_REG, 7, 0x00, RV_TYPE_R},

    // RV32M Standard Extension
    {"MUL", OP_REG, 0, 0x01, RV_TYPE_R},
    {"mul", OP_REG, 0, 0x01, RV_TYPE_R},
    {"MULH", OP_REG, 1, 0x01, RV_TYPE_R},
    {"mulh", OP_REG, 1, 0x01, RV_TYPE_R},
    {"MULHSU", OP_REG, 2, 0x01, RV_TYPE_R},
    {"mulhsu", OP_REG, 2, 0x01, RV_TYPE_R},
    {"MULHU", OP_REG, 3, 0x01, RV_TYPE_R},
    {"mulhu", OP_REG, 3, 0x01, RV_TYPE_R},
    {"DIV", OP_REG, 4, 0x01, RV_TYPE_R},
    {"div", OP_REG, 4, 0x01, RV_TYPE_R},
    {"DIVU", OP_REG, 5, 0x01, RV_TYPE_R},
    {"divu", OP_REG, 5, 0x01, RV_TYPE_R},
    {"REM", OP_REG, 6, 0x01, RV_TYPE_R},
    {"rem", OP_REG, 6, 0x01, RV_TYPE_R},
    {"REMU", OP_REG, 7, 0x01, RV_TYPE_R},
    {"remu", OP_REG, 7, 0x01, RV_TYPE_R},

    // System
    {"ECALL", OP_SYSTEM, 0, 0, RV_TYPE_I},
    {"ecall", OP_SYSTEM, 0, 0, RV_TYPE_I},
    {"EBREAK", OP_SYSTEM, 0, 0, RV_TYPE_I},
    {"ebreak", OP_SYSTEM, 0, 0, RV_TYPE_I},
    {"CSRRW", OP_SYSTEM, 0x1, 0, RV_TYPE_I},
    {"csrrw", OP_SYSTEM, 0x1, 0, RV_TYPE_I},
    {"CSRRS", OP_SYSTEM, 0x2, 0, RV_TYPE_I},
    {"csrrs", OP_SYSTEM, 0x2, 0, RV_TYPE_I},
    {"CSRRC", OP_SYSTEM, 0x3, 0, RV_TYPE_I},
    {"csrrc", OP_SYSTEM, 0x3, 0, RV_TYPE_I},
    {"MRET", OP_SYSTEM, 0x0, 0x30, RV_TYPE_I},
    {"mret", OP_SYSTEM, 0x0, 0x30, RV_TYPE_I},

    // Helper mappings for legacy support (Pseudo-instructions)
    {"JMP", OP_JAL, 0, 0, RV_PSEUDO}, // jal x0, label
    {"jmp", OP_JAL, 0, 0, RV_PSEUDO},
    {"RET", OP_JALR, 0, 0, RV_PSEUDO}, // jalr x0, 0(ra)
    {"ret", OP_JALR, 0, 0, RV_PSEUDO},
    {"CALL", OP_JAL, 0, 0, RV_PSEUDO}, // jal ra, label (pseudo)
    {"call", OP_JAL, 0, 0, RV_PSEUDO},

    {"JZ", OP_BRANCH, 0, 0, RV_PSEUDO}, // beq rs1, x0, label
    {"jz", OP_BRANCH, 0, 0, RV_PSEUDO},
    {"JNZ", OP_BRANCH, 1, 0, RV_PSEUDO}, // bne rs1, x0, label
    {"jnz", OP_BRANCH, 1, 0, RV_PSEUDO},

    {"MOVE", OP_IMM, 0, 0, RV_PSEUDO}, // addi rd, rs1, 0
    {"move", OP_IMM, 0, 0, RV_PSEUDO},
    {"MOV", OP_IMM, 0, 0, RV_PSEUDO},
    {"mov", OP_IMM, 0, 0, RV_PSEUDO},
    {"MV", OP_IMM, 0, 0, RV_PSEUDO},
    {"mv", OP_IMM, 0, 0, RV_PSEUDO},

    {"LOADI", OP_LUI, 0, 0, RV_PSEUDO}, // lui+addi
    {"loadi", OP_LUI, 0, 0, RV_PSEUDO},

    {"HALT", OP_CUSTOM_HALT, 0, 0, RV_PSEUDO}, // Custom halt
    {"halt", OP_CUSTOM_HALT, 0, 0, RV_PSEUDO},

    // New Pseudos for Codegen
    {"LA", OP_LUI, 0, 0, RV_PSEUDO}, // Load Address
    {"la", OP_LUI, 0, 0, RV_PSEUDO},
    {"LI", OP_IMM, 0, 0, RV_PSEUDO}, // Load Immediate
    {"li", OP_IMM, 0, 0, RV_PSEUDO},
    {"J", OP_JAL, 0, 0, RV_PSEUDO}, // Unconditional Jump (jal x0, offset)
    {"j", OP_JAL, 0, 0, RV_PSEUDO},
    {"NOT", OP_IMM, 0, 0, RV_PSEUDO}, // xori rd, rs1, -1
    {"not", OP_IMM, 0, 0, RV_PSEUDO},
    {"NEG", OP_REG, 0, 0, RV_PSEUDO}, // sub rd, x0, rs1
    {"neg", OP_REG, 0, 0, RV_PSEUDO},
};

static int num_instructions = sizeof(instructions) / sizeof(instructions[0]);

// Global state
static label_t labels[MAX_LABELS];
static int num_labels = 0;
static assembled_inst_t assembled[MAX_INSTRUCTIONS];
static int num_assembled = 0;
static data_word_t data_words[MAX_DATA_WORDS];
static int num_data_words = 0;
static uint32_t current_address = 0;

// Stack pointer and frame pointer registers
static const int SP_REG = 30; // R30 = stack pointer
static const int FP_REG = 31; // R31 = frame pointer

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
  while (isspace(*str))
    str++;

  // Trim trailing whitespace
  char *end = str + strlen(str) - 1;
  while (end > str && isspace(*end))
    *end-- = '\0';

  return str;
}

static int parse_register(const char *token) {
  if (!token)
    return -1;

  // ABI Names
  if (strcasecmp(token, "zero") == 0)
    return 0;
  if (strcasecmp(token, "ra") == 0)
    return 1;
  if (strcasecmp(token, "sp") == 0)
    return 2;
  if (strcasecmp(token, "gp") == 0)
    return 3;
  if (strcasecmp(token, "tp") == 0)
    return 4;
  if (strcasecmp(token, "fp") == 0)
    return 8; // s0/fp

  // Standard x0-x31
  if (token[0] == 'x' || token[0] == 'X') {
    int reg = atoi(token + 1);
    if (reg >= 0 && reg < 32)
      return reg;
  }

  // Legacy r0-r31 support
  if (token[0] == 'r' || token[0] == 'R') {
    // Only if followed by digits
    if (isdigit(token[1])) {
      int reg = atoi(token + 1);
      if (reg >= 0 && reg < 32)
        return reg;
    }
  }

  // t0-t6 (x5-x7, x28-x31)
  if (token[0] == 't' || token[0] == 'T') {
    int idx = atoi(token + 1);
    if (idx >= 0 && idx <= 2)
      return 5 + idx; // t0-t2 -> x5-x7
    if (idx >= 3 && idx <= 6)
      return 28 + (idx - 3); // t3-t6 -> x28-x31
  }

  // s0-s11 (x8-x9, x18-x27)
  if (token[0] == 's' || token[0] == 'S') {
    int idx = atoi(token + 1);
    if (idx == 0 || idx == 1)
      return 8 + idx; // s0-s1 -> x8-x9
    if (idx >= 2 && idx <= 11)
      return 18 + (idx - 2); // s2-s11 -> x18-x27
  }

  // a0-a7 (x10-x17)
  if (token[0] == 'a' || token[0] == 'A') {
    int idx = atoi(token + 1);
    if (idx >= 0 && idx <= 7)
      return 10 + idx; // a0-a7 -> x10-x17
  }

  return -1;
}

static int parse_immediate(const char *str) {
  // Skip whitespace and commas
  while (*str && (isspace(*str) || *str == ','))
    str++;

  if (*str == '#')
    str++; // Skip optional '#'

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
static bool parse_memory_ref(const char *str, int *reg, int *offset,
                             char *label) {
  // Skip whitespace and commas
  while (*str && (isspace(*str) || *str == ','))
    str++;

  *reg = -1;
  *offset = 0;
  label[0] = '\0';

  if (*str != '[')
    return false;
  str++; // Skip '['

  // Find the closing bracket
  const char *end = strchr(str, ']');
  if (!end)
    return false;

  // Copy the content between brackets
  int len = end - str;
  char content[256];
  strncpy(content, str, len);
  content[len] = '\0';

  // Check if it's a register reference
  if (content[0] == 'r' || content[0] == 'R') {
    *reg = parse_register(content);
    if (*reg < 0)
      return false;

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

static bool find_label(const char *name, uint32_t *address) {
  for (int i = 0; i < num_labels; i++) {
    if (strcmp(labels[i].name, name) == 0) {
      if (address)
        *address = labels[i].address;
      return true;
    }
  }
  return false;
}

static uint32_t encode_raw(opcode_t opcode, inst_type_t type, uint8_t funct3,
                           uint8_t funct7, int rd, int rs1, int rs2,
                           int immediate) {
  switch (type) {
  case RV_TYPE_R:
    return (funct7 << 25) | ((rs2 & 0x1F) << 20) | ((rs1 & 0x1F) << 15) |
           (funct3 << 12) | ((rd & 0x1F) << 7) | opcode;

  case RV_TYPE_I:
    return ((immediate & 0xFFF) << 20) | ((rs1 & 0x1F) << 15) | (funct3 << 12) |
           ((rd & 0x1F) << 7) | opcode;

  case RV_TYPE_S:
    return (((immediate >> 5) & 0x7F) << 25) | ((rs2 & 0x1F) << 20) |
           ((rs1 & 0x1F) << 15) | (funct3 << 12) | ((immediate & 0x1F) << 7) |
           opcode;

  case RV_TYPE_B: {
    // B-type immediate: imm[12|10:5|4:1|11]
    uint32_t imm12 = (immediate >> 12) & 1;
    uint32_t imm10_5 = (immediate >> 5) & 0x3F;
    uint32_t imm4_1 = (immediate >> 1) & 0xF;
    uint32_t imm11 = (immediate >> 11) & 1;
    return (imm12 << 31) | (imm10_5 << 25) | ((rs2 & 0x1F) << 20) |
           ((rs1 & 0x1F) << 15) | (funct3 << 12) | (imm4_1 << 8) |
           (imm11 << 7) | opcode;
  }

  case RV_TYPE_U:
    return ((immediate & 0xFFFFF) << 12) | ((rd & 0x1F) << 7) | opcode;

  case RV_TYPE_J: {
    // J-type immediate: imm[20|10:1|11|19:12]
    uint32_t imm20 = (immediate >> 20) & 1;
    uint32_t imm10_1 = (immediate >> 1) & 0x3FF;
    uint32_t imm11 = (immediate >> 11) & 1;
    uint32_t imm19_12 = (immediate >> 12) & 0xFF;
    return (imm20 << 31) | (imm19_12 << 12) | (imm11 << 20) | (imm10_1 << 21) |
           ((rd & 0x1F) << 7) | opcode;
  }

  default:
    return 0;
  }
}

static uint32_t encode_instruction(const instruction_def_t *inst, int rd,
                                   int rs1, int rs2, int immediate) {
  return encode_raw(inst->opcode, inst->type, inst->funct3, inst->funct7, rd,
                    rs1, rs2, immediate);
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

    current_address += 4; // Each word is 4 bytes
  }
  // Handle .string directive - convert string to bytes
  else if (strncasecmp(line, ".string", 7) == 0) {
    char *string_content = (char *)line + 7;
    string_content = trim_whitespace(string_content);

    // Remove quotes if present
    if (string_content[0] == '"') {
      string_content++;
      char *end_quote = strrchr(string_content, '"');
      if (end_quote)
        *end_quote = '\0';
    }

    // Convert string to data words (4 bytes per word)
    int len = strlen(string_content);
    for (int i = 0; i < len; i += 4) {
      if (num_data_words >= MAX_DATA_WORDS) {
        error("Too many data words", line_num);
      }

      uint32_t word = 0;
      for (int j = 0; j < 4 && (i + j) < len; j++) {
        char c = string_content[i + j];
        // Handle escape sequences
        if (c == '\\' && (i + j + 1) < len) {
          switch (string_content[i + j + 1]) {
          case 'n':
            c = '\n';
            j++;
            break;
          case 't':
            c = '\t';
            j++;
            break;
          case 'r':
            c = '\r';
            j++;
            break;
          case '\\':
            c = '\\';
            j++;
            break;
          case '"':
            c = '"';
            j++;
            break;
          }
        }
        word |= ((uint32_t)(c & 0xFF)) << (j * 8);
      }

      data_words[num_data_words].address = current_address;
      data_words[num_data_words].value = word;
      data_words[num_data_words].label[0] = '\0';
      num_data_words++;

      current_address += 4;
    }

    // Add null terminator if needed
    if (len % 4 != 0 || len == 0) {
      // The null terminator is already included in the last word
    } else {
      // Need an extra word for null terminator
      if (num_data_words >= MAX_DATA_WORDS) {
        error("Too many data words", line_num);
      }

      data_words[num_data_words].address = current_address;
      data_words[num_data_words].value = 0; // Null terminator
      data_words[num_data_words].label[0] = '\0';
      num_data_words++;

      current_address += 4;
    }
  }
}

// Check if a string looks like a label name (not a number)
static bool is_label_name(const char *str) {
  if (!str || *str == '\0')
    return false;

  // Skip leading whitespace
  while (isspace(*str))
    str++;

  // If it starts with '#' or is a number, it's not a label
  if (*str == '#')
    return false;
  if (*str == '-' || *str == '+')
    str++; // Skip sign
  if (isdigit(*str)) {
    // Check if entire string is numeric
    while (isdigit(*str) || *str == 'x' || *str == 'X' ||
           (*str >= 'a' && *str <= 'f') || (*str >= 'A' && *str <= 'F')) {
      str++;
    }
    return (*str != '\0'); // If we didn't reach end, it's not purely numeric
  }

  // Must start with letter or underscore for a valid label
  return (isalpha(*str) || *str == '_');
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
    if (*p == ',' && *(p + 1) != ' ') {
      *p = ' ';
    }
  }

  // Manual tokenization
  char *start = line_copy;
  while (*start && num_tokens < 10) {
    // Skip whitespace
    while (*start && isspace(*start))
      start++;
    if (!*start)
      break;

    if (*start == ',') {
      start++;
      continue;
    }

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
    while (*end && !isspace(*end) && *end != ',' && *end != '[')
      end++;

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

  if (num_tokens == 0)
    return;

  const instruction_def_t *inst = find_instruction(tokens[0]);
  if (!inst) {
    char msg[256];
    snprintf(msg, sizeof(msg), "Unknown instruction: %s", tokens[0]);
    error(msg, line_num);
  }

  uint32_t encoded = 0;
  int rd = 0, rs1 = 0, rs2 = 0, immediate = 0;
  bool needs_resolution = false;
  char forward_label[MAX_LABEL_LENGTH] = "";

  // Create a working copy of the instruction definition to handle pseudos
  instruction_def_t work_inst = *inst;

  // Handle Pseudo-instructions mapping to Real types
  if (work_inst.type == RV_PSEUDO) {
    if (work_inst.opcode == OP_JAL) { // JMP, CALL -> JAL
      work_inst.type = RV_TYPE_J;
      if (strcasecmp(work_inst.name, "CALL") == 0 ||
          strcasecmp(work_inst.name, "call") == 0) {
        rd = 1; // ra
      } else {
        rd = 0; // x0
      }
    } else if (work_inst.opcode == OP_JALR) { // RET -> JALR
      work_inst.type = RV_TYPE_I;
      rd = 0;
      rs1 = 1; // ra
      immediate = 0;
    } else if (work_inst.opcode == OP_BRANCH) { // JZ, JNZ -> BEQ, BNE
      work_inst.type = RV_TYPE_B;
    } else if (work_inst.opcode == OP_IMM) { // MOVE, NOT, LI -> ADDI/XORI
      if (strcasecmp(work_inst.name, "NOT") == 0 ||
          strcasecmp(work_inst.name, "not") == 0) {
        work_inst.opcode = OP_IMM; // XORI is OP_IMM with funct3=4
        work_inst.funct3 = 4;      // XORI
        immediate = -1;
      } else if (strcasecmp(work_inst.name, "LI") == 0 ||
                 strcasecmp(work_inst.name, "li") == 0) {
        // LI is complex. Handled in switch below or mapped to ADDI/LUI.
        // If small, map to ADDI. large to LUI/ADDI.
        // For now, map to I-type ADDI as placeholder, special handling later.
        work_inst.type = RV_TYPE_I;
      } else {
        work_inst.type = RV_TYPE_I; // MOVE -> ADDI
      }
    } else if (work_inst.opcode == OP_LUI) { // LOADI, LA -> LUI (partial)
      // LA is handled specially
      work_inst.type = RV_TYPE_U;                    // Initial mapping
    } else if (work_inst.opcode == OP_CUSTOM_HALT) { // HALT -> EBREAK
      work_inst.type = RV_TYPE_I;
      work_inst.opcode = OP_SYSTEM;
      work_inst.funct3 = 0;
      work_inst.funct7 = 0;
      immediate = 1;                         // EBREAK
    } else if (work_inst.opcode == OP_REG) { // NEG
      if (strcasecmp(work_inst.name, "NEG") == 0 ||
          strcasecmp(work_inst.name, "neg") == 0) {
        work_inst.type = RV_TYPE_R;
        work_inst.opcode = OP_REG; // SUB is OP_REG with funct3=0, funct7=0x20
        work_inst.funct3 = 0;
        work_inst.funct7 = 0x20; // SUB
        rs1 = 0; // x0 will be set later? No, NEG rd, rs -> SUB rd, x0, rs
        // Parsing will extract rd, rs(as rs2?).
        // SUB rd, rs1, rs2. we want rs1=x0, rs2=src.
      }
    }
  }

  // Special handling for multi-instruction pseudos before main switch
  if ((strcasecmp(work_inst.name, "LA") == 0 ||
       strcasecmp(work_inst.name, "la") == 0) ||
      (strcasecmp(work_inst.name, "LI") == 0 ||
       strcasecmp(work_inst.name, "li") == 0)) {

    int val = 0;
    bool is_label = false;

    rd = parse_register(tokens[1]);
    if (num_tokens > 2) {
      // For LA: token[2] is label. For LI: token[2] is imm.
      if (strcasecmp(work_inst.name, "LA") == 0 ||
          strcasecmp(work_inst.name, "la") == 0) {
        uint32_t label_addr;
        if (find_label(tokens[2], &label_addr)) {
          val = (int32_t)label_addr;
        } else {
          val = 0;
          // Check if it's a numeric constant even with LA
          if (isdigit(tokens[2][0]) ||
              (tokens[2][0] == '0' &&
               (tokens[2][1] == 'x' || tokens[2][1] == 'X'))) {
            val = parse_immediate(tokens[2]);
          } else {
            needs_resolution = true;
            strcpy(forward_label, tokens[2]);
          }
        }
        is_label = true;
      } else {
        val = parse_immediate(tokens[2]);
      }
    }

    // Check sizes
    // Since we need to support full 32-bit addresses/values, we emit 2
    // instructions always for uniformity? Or optimize? Optimizing changes
    // size, complicates 2nd pass if size differs. Safe bet: Always 2
    // instructions (AUIPC+ADDI or LUI+ADDI). LUI+ADDI is simpler for
    // absolute.

    // Instruction 1: LUI rd, val>>12 (+1 if bit 11 set? Sign ext issues).
    // RISC-V LUI loads 20 upper bits. ADDI adds 12-bit signed.
    // If bit 11 of low part is 1, ADDI will subtract, so we need to add
    // 0x1000 to high part. Logic: int hi = (val + 0x800) >> 12; int lo = val
    // & 0xFFF; (sign extended lo). But we don't know val in pass 1 if forward
    // ref.

    // We just emit placeholders.

    // Inst 1: LUI rd, upper
    int hi = (val + 0x800) >> 12;
    encoded = encode_raw(OP_LUI, RV_TYPE_U, 0, 0, rd, 0, 0, hi);

    // Store Inst 1
    if (num_assembled >= MAX_INSTRUCTIONS)
      error("Too many instructions", line_num);
    assembled[num_assembled].address = current_address;
    assembled[num_assembled].instruction = encoded;
    strncpy(assembled[num_assembled].source_line, line, MAX_LINE_LENGTH - 1);
    assembled[num_assembled].source_line[MAX_LINE_LENGTH - 1] = '\0';
    assembled[num_assembled].needs_resolution =
        needs_resolution; // Resolve later
    if (needs_resolution) {
      // Mark special type for LA/LI resolution
      assembled[num_assembled].type = RV_TYPE_U; // LUI part
      strncpy(assembled[num_assembled].forward_label, forward_label,
              MAX_LABEL_LENGTH);
      assembled[num_assembled].rd = rd;
      assembled[num_assembled].opcode = OP_LUI; // Mark looking for LUI
    }
    num_assembled++;
    current_address += 4;

    // Inst 2: ADDI rd, rd, lower
    int lo = val & 0xFFF;
    encoded = encode_raw(OP_IMM, RV_TYPE_I, 0, 0, rd, rd, 0, lo);

    if (num_assembled >= MAX_INSTRUCTIONS)
      error("Too many instructions", line_num);
    assembled[num_assembled].address = current_address;
    assembled[num_assembled].instruction = encoded;
    strncpy(assembled[num_assembled].source_line, "  (la/li part 2)",
            MAX_LINE_LENGTH - 1);
    assembled[num_assembled].source_line[MAX_LINE_LENGTH - 1] = '\0';
    assembled[num_assembled].needs_resolution = needs_resolution;
    if (needs_resolution) {
      assembled[num_assembled].type = RV_TYPE_I; // ADDI part
      strncpy(assembled[num_assembled].forward_label, forward_label,
              MAX_LABEL_LENGTH);
      assembled[num_assembled].rd = rd;
      assembled[num_assembled].rs1 = rd;
      assembled[num_assembled].opcode = OP_IMM; // Mark looking for ADDI
    }
    num_assembled++;
    current_address += 4;

    return; // Done
  }

  switch (work_inst.type) {
  case RV_TYPE_R:
    // ADD rd, rs1, rs2
    if (strcasecmp(work_inst.name, "NEG") == 0 ||
        strcasecmp(work_inst.name, "neg") == 0) {
      if (num_tokens < 3)
        error("Missing operands for NEG", line_num);
      rd = parse_register(tokens[1]);
      rs2 = parse_register(tokens[2]);
      rs1 = 0; // x0
      // SUB rd, x0, rs2
      encoded = encode_raw(OP_REG, RV_TYPE_R, 0, 0x20, rd, rs1, rs2, 0);
    } else {
      if (num_tokens < 4)
        error("Missing register operands", line_num);
      rd = parse_register(tokens[1]);
      rs1 = parse_register(tokens[2]);
      rs2 = parse_register(tokens[3]);
      if (rd < 0 || rs1 < 0 || rs2 < 0)
        error("Invalid register", line_num);
      encoded = encode_instruction(&work_inst, rd, rs1, rs2, 0);
    }
    break;

  case RV_TYPE_I:
    // ADDI rd, rs1, imm  OR  LW rd, offset(rs1)
    if (work_inst.opcode == OP_LOAD) { // Load instructions
      // Support LW rd, offset(rs1) OR LW rd, [rs1+offset] (legacy)
      rd = parse_register(tokens[1]);
      if (rd < 0)
        error("Invalid register", line_num);

      // Check format
      if (num_tokens >= 3) {
        char *mem_op = tokens[2];
        if (mem_op[0] == '[') { // [rs1+offset] legacy
          int mem_reg, mem_off;
          char mem_lbl[64];
          if (parse_memory_ref(mem_op, &mem_reg, &mem_off, mem_lbl)) {
            rs1 = mem_reg;
            immediate = mem_off;
          }
        } else {
          // Try offset(rs1) standard format or immediate referencing a label
          char *paren = strchr(mem_op, '(');
          if (paren) {
            // offset(rs1)
            char off_str[64];
            char reg_str[64];
            // Simple parsing: split at (
            *paren = '\0';
            strcpy(off_str, mem_op);
            strcpy(reg_str, paren + 1);
            char *close_paren = strchr(reg_str, ')');
            if (close_paren)
              *close_paren = '\0';

            immediate = parse_immediate(off_str);
            rs1 = parse_register(reg_str);
          } else {
            // Just immediate/label
            immediate = parse_immediate(mem_op); // Might be 0 if label
            rs1 = 0;
          }
        }
      }
    } else if (work_inst.opcode == OP_JALR) {
      // JALR rd, rs1, offset OR RET (handled in pseudo)
      // Or JALR rd, offset(rs1)
      if (inst->type == RV_PSEUDO && (strcasecmp(work_inst.name, "RET") == 0 ||
                                      strcasecmp(work_inst.name, "ret") == 0)) {
        rd = 0;  // x0 plays no role in return, usually ignored
        rs1 = 1; // ra
        immediate = 0;
      } else if (num_tokens >= 2) {
        // Logic for explicit JALR if needed
      }
    } else if (strcasecmp(work_inst.name, "NOT") == 0 ||
               strcasecmp(work_inst.name, "not") == 0) {
      // NOT rd, rs -> XORI rd, rs, -1
      rd = parse_register(tokens[1]);
      rs1 = parse_register(tokens[2]);
      immediate = -1;
      encoded = encode_instruction(&work_inst, rd, rs1, 0, immediate);
    } else {
      // Check for CSR instructions (I-type) or System instructions
      if (inst->opcode == OP_SYSTEM) {
        if (strcasecmp(inst->name, "CSRRW") == 0 ||
            strcasecmp(inst->name, "csrrw") == 0 ||
            strcasecmp(inst->name, "CSRRS") == 0 ||
            strcasecmp(inst->name, "csrrs") == 0 ||
            strcasecmp(inst->name, "CSRRC") == 0 ||
            strcasecmp(inst->name, "csrrc") == 0) {

          if (num_tokens < 4)
            error("Missing operands for CSR", line_num);
          rd = parse_register(tokens[1]);
          immediate = parse_immediate(tokens[2]); // CSR address
          rs1 = parse_register(tokens[3]);
        } else if (strcasecmp(inst->name, "EBREAK") == 0 ||
                   strcasecmp(inst->name, "ebreak") == 0 ||
                   strcasecmp(inst->name, "HALT") == 0 ||
                   strcasecmp(inst->name, "halt") == 0) {
          rd = 0;
          rs1 = 0;
          immediate = 1; // imm[0]=1 for EBREAK/HALT convention in this core
        } else if (strcasecmp(inst->name, "ECALL") == 0 ||
                   strcasecmp(inst->name, "ecall") == 0) {
          rd = 0;
          rs1 = 0;
          immediate = 0;
        } else if (strcasecmp(inst->name, "MRET") == 0 ||
                   strcasecmp(inst->name, "mret") == 0) {
          rd = 0;
          rs1 = 0;
          immediate = 0x302; // MRET encoding
        } else {
          error("Unknown system instruction", line_num);
        }
      } else if (inst->type == RV_PSEUDO &&
                 (strcasecmp(inst->name, "MOV") == 0 ||
                  strcasecmp(inst->name, "MOVE") == 0 ||
                  strcasecmp(inst->name, "MV") == 0 ||
                  strcasecmp(inst->name, "mv") == 0)) {
        // ... existing MOV logic ...
        rd = parse_register(tokens[1]);
        rs1 = parse_register(tokens[2]);
        immediate = 0;
      } else {
        if (num_tokens < 4)
          error("Missing operands", line_num);
        rd = parse_register(tokens[1]);
        rs1 = parse_register(tokens[2]);
        immediate = parse_immediate(tokens[3]);
      }
    }
    if (rd < 0 || rs1 < 0)
      error("Invalid register", line_num);
    encoded = encode_instruction(&work_inst, rd, rs1, 0, immediate);
    break;

  case RV_TYPE_S:
    // SB rs2, offset(rs1)
    if (num_tokens < 3)
      error("Missing operands", line_num);
    rs2 = parse_register(tokens[1]); // Source data

    // Memory operand
    char *mem_op_s = tokens[2];
    if (mem_op_s[0] == '[') {
      int mem_reg, mem_off;
      char mem_lbl[64];
      if (parse_memory_ref(mem_op_s, &mem_reg, &mem_off, mem_lbl)) {
        rs1 = mem_reg;
        immediate = mem_off;
      }
    } else {
      char *paren = strchr(mem_op_s, '(');
      if (paren) {
        char off_str[64];
        char reg_str[64];
        *paren = '\0';
        strcpy(off_str, mem_op_s);
        strcpy(reg_str, paren + 1);
        char *close_paren = strchr(reg_str, ')');
        if (close_paren)
          *close_paren = '\0';
        immediate = parse_immediate(off_str);
        rs1 = parse_register(reg_str);
      }
    }
    if (rs1 < 0 || rs2 < 0)
      error("Invalid register", line_num);
    encoded = encode_instruction(&work_inst, 0, rs1, rs2, immediate);
    break;

  case RV_TYPE_B:
    // BEQ rs1, rs2, label
    if (inst->type == RV_PSEUDO) { // JZ/JNZ
      rs1 = parse_register(tokens[1]);
      rs2 = 0; // x0
      // Target is token 2
      uint32_t label_addr;
      if (find_label(tokens[2], &label_addr)) {
        immediate = label_addr - current_address;
      } else {
        immediate = 0;
        needs_resolution = true;
        strcpy(forward_label, tokens[2]);
      }
    } else {
      rs1 = parse_register(tokens[1]);
      rs2 = parse_register(tokens[2]);
      // Target is token 3
      uint32_t label_addr;
      if (find_label(tokens[3], &label_addr)) {
        immediate = label_addr - current_address;
      } else {
        immediate = 0;
        needs_resolution = true;
        strcpy(forward_label, tokens[3]);
      }
    }
    encoded = encode_instruction(&work_inst, 0, rs1, rs2, immediate);
    break;

  case RV_TYPE_U:
    // LUI rd, imm
    rd = parse_register(tokens[1]);
    if (num_tokens > 2) {
      uint32_t label_addr;
      if (find_label(tokens[2], &label_addr)) {
        immediate = label_addr;
      } else if (isdigit(tokens[2][0]) || tokens[2][0] == '-') {
        immediate = parse_immediate(tokens[2]);
      } else {
        immediate = 0;
        needs_resolution = true;
        strcpy(forward_label, tokens[2]);
      }
    }
    encoded = encode_instruction(&work_inst, rd, 0, 0, immediate);
    break;

  case RV_TYPE_J:
    // JAL rd, label
    if (inst->type == RV_PSEUDO) { // JMP/CALL/J
      if (strcasecmp(inst->name, "JMP") == 0 ||
          strcasecmp(inst->name, "jmp") == 0 ||
          strcasecmp(inst->name, "CALL") == 0 ||
          strcasecmp(inst->name, "call") == 0 ||
          strcasecmp(inst->name, "J") == 0 ||
          strcasecmp(inst->name, "j") == 0) {
        // rd set above in pseudo block (JMP/J -> x0, CALL -> ra)
        if (strcasecmp(work_inst.name, "J") == 0 ||
            strcasecmp(work_inst.name, "j") == 0) {
          // j label -> jal x0, label
          rd = 0; // x0
        }

        uint32_t label_addr;
        if (find_label(tokens[1], &label_addr)) {
          immediate = label_addr - current_address;
        } else {
          immediate = 0;
          needs_resolution = true;
          strcpy(forward_label, tokens[1]);
        }
      }
    } else {
      rd = parse_register(tokens[1]);
      uint32_t label_addr;
      if (find_label(tokens[2], &label_addr)) {
        immediate = label_addr - current_address;
      } else {
        immediate = 0;
        needs_resolution = true;
        strcpy(forward_label, tokens[2]);
      }
    }
    encoded = encode_instruction(&work_inst, rd, 0, 0, immediate);
    break;

  default:
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
  assembled[num_assembled].needs_resolution = needs_resolution;

  if (needs_resolution) {
    strncpy(assembled[num_assembled].forward_label, forward_label,
            MAX_LABEL_LENGTH - 1);
    assembled[num_assembled].forward_label[MAX_LABEL_LENGTH - 1] = '\0';
    assembled[num_assembled].opcode = work_inst.opcode;
    assembled[num_assembled].funct3 = work_inst.funct3;
    assembled[num_assembled].funct7 = work_inst.funct7;
    assembled[num_assembled].rd = rd;
    assembled[num_assembled].rs1 = rs1;
    assembled[num_assembled].rs2 = rs2;
    assembled[num_assembled].type = work_inst.type;
    assembled[num_assembled].imm = 0;
  }
  num_assembled++;

  current_address += 4;
}

static void first_pass(FILE *input) {
  char line[MAX_LINE_LENGTH];
  int line_num = 0;

  while (fgets(line, sizeof(line), input)) {
    line_num++;
    // printf("Line %d: %s", line_num, line);

    // Remove comments (both ; and // style)
    char *comment = strstr(line, ";");
    if (comment)
      *comment = '\0';
    comment = strstr(line, "//");
    if (comment)
      *comment = '\0';

    char *trimmed = trim_whitespace(line);
    if (strlen(trimmed) == 0)
      continue;

    // Skip lines that are just quotes or string continuation (from multi-line
    // string literals)
    if (strlen(trimmed) == 1 &&
        (trimmed[0] == '"' || trimmed[0] == '\'' || trimmed[0] == '`')) {
      continue;
    }

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
  printf("Starting second pass\n");
  // Resolve forward references now that we know all label addresses
  for (int i = 0; i < num_assembled; i++) {
    if (assembled[i].needs_resolution) {
      uint32_t label_addr;
      if (find_label(assembled[i].forward_label, &label_addr)) {
        int32_t immediate = 0;

        // Calculate offsets for branches/jumps
        if (assembled[i].type == RV_TYPE_B || assembled[i].type == RV_TYPE_J) {
          // PC-relative offset
          immediate = (int32_t)label_addr - (int32_t)assembled[i].address;
        } else if (assembled[i].type == RV_TYPE_U) {
          // LUI/AUIPC absolute high
          immediate = (int32_t)(label_addr + 0x800) >> 12;
        } else if (assembled[i].type == RV_TYPE_I &&
                   assembled[i].opcode == OP_IMM) {
          // ADDI low part (signed 12-bit)
          immediate = (int32_t)label_addr & 0xFFF;
        } else if (assembled[i].type == RV_TYPE_I) {
          immediate = (int32_t)label_addr & 0xFFF;
        } else {
          immediate = (int32_t)label_addr; // Fallback
        }

        assembled[i].instruction = encode_raw(
            assembled[i].opcode, assembled[i].type, assembled[i].funct3,
            assembled[i].funct7, assembled[i].rd, assembled[i].rs1,
            assembled[i].rs2, immediate);
        assembled[i].needs_resolution = false;
      } else {
        printf("ERROR: Could not resolve forward reference to label: %s\n",
               assembled[i].forward_label);
        exit(1);
      }
    }
  }
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

static void write_binary_output(FILE *output) {
  // Write assembled instructions in little-endian (RISC-V native)
  for (int i = 0; i < num_assembled; i++) {
    uint32_t val = assembled[i].instruction;
    fwrite(&val, 4, 1, output);
  }

  // Write data words
  for (int i = 0; i < num_data_words; i++) {
    uint32_t val = data_words[i].value;
    fwrite(&val, 4, 1, output);
  }
}

static void print_listing(void) {
  printf("Address  | Machine Code | Source\n");
  printf("---------|--------------|--------\n");

  // Print instructions
  for (int i = 0; i < num_assembled; i++) {
    printf("%08X | %08X     | %s\n", assembled[i].address,
           assembled[i].instruction, assembled[i].source_line);
  }

  // Print data words
  for (int i = 0; i < num_data_words; i++) {
    printf("%08X | %08X     | .word %s\n", data_words[i].address,
           data_words[i].value,
           data_words[i].label[0] ? data_words[i].label : "");
  }

  if (num_labels > 0) {
    printf("\nLabels:\n");
    for (int i = 0; i < num_labels; i++) {
      printf("%-20s = 0x%08X %s\n", labels[i].name, labels[i].address,
             labels[i].is_data ? "(data)" : "");
    }
  }
}

int main(int argc, char *argv[]) {
  if (argc < 2) {
    fprintf(stderr, "Usage: %s <input.asm> [output.hex/bin] [options]\n",
            argv[0]);
    fprintf(stderr, "Options:\n");
    fprintf(stderr, "  -o <file>: Specify output file\n");
    fprintf(stderr, "  -b: Binary output mode (default is HEX)\n");
    fprintf(stderr, "  -l: Print assembly listing\n");
    return 1;
  }

  const char *input_filename = NULL;
  const char *output_filename = "output.hex";
  bool binary_mode = false;
  bool print_listing_flag = false;

  for (int i = 1; i < argc; i++) {
    if (strcmp(argv[i], "-o") == 0 && i + 1 < argc) {
      output_filename = argv[++i];
    } else if (strcmp(argv[i], "-b") == 0) {
      binary_mode = true;
    } else if (strcmp(argv[i], "-l") == 0) {
      print_listing_flag = true;
    } else if (argv[i][0] != '-') {
      if (input_filename == NULL) {
        input_filename = argv[i];
      } else {
        output_filename = argv[i];
      }
    }
  }

  if (input_filename == NULL) {
    fprintf(stderr, "Error: No input file specified\n");
    return 1;
  }

  // Auto-detect binary mode from extension if not explicitly set
  if (!binary_mode && output_filename &&
      (strstr(output_filename, ".bin") || strstr(output_filename, ".obj"))) {
    binary_mode = true;
  }

  FILE *input = fopen(input_filename, "r");
  if (!input) {
    fprintf(stderr, "Error: Cannot open input file %s\n", input_filename);
    return 1;
  }

  FILE *output = fopen(output_filename, binary_mode ? "wb" : "w");
  if (!output) {
    fprintf(stderr, "Error: Cannot create output file %s\n", output_filename);
    fclose(input);
    return 1;
  }

  printf("Enhanced Assembling %s -> %s (%s mode)\n", input_filename,
         output_filename, binary_mode ? "binary" : "hex");

  // Two-pass assembly
  first_pass(input);
  second_pass();

  // Write output
  if (binary_mode) {
    write_binary_output(output);
  } else {
    write_hex_output(output);
  }

  printf("Assembly complete: %d instructions, %d data words, %d labels\n",
         num_assembled, num_data_words, num_labels);

  if (print_listing_flag) {
    print_listing();
  }

  fclose(input);
  fclose(output);

  return 0;
}
