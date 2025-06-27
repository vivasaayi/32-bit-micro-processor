/*
 * Enhanced C-to-Assembly Compiler for Data Structure & Algorithm Support
 * 
 * Key improvements:
 * - Array support (static arrays)
 * - Pointer support (basic pointer arithmetic)
 * - Structure support (basic structs)
 * - Enhanced expression parsing
 * - Better memory management
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <stdbool.h>

#define MAX_TOKEN_LEN 256
#define MAX_TOKENS 10000
#define MAX_CODE_LINES 10000
#define MAX_VARIABLES 1000
#define MAX_STRUCTS 100
#define MAX_LABELS 1000

// Enhanced token types
typedef enum {
    // Literals
    TOK_NUMBER,
    TOK_IDENTIFIER,
    TOK_STRING,
    
    // Keywords
    TOK_INT,
    TOK_VOID,
    TOK_STRUCT,
    TOK_IF,
    TOK_ELSE,
    TOK_WHILE,
    TOK_FOR,
    TOK_RETURN,
    TOK_SIZEOF,
    
    // Operators
    TOK_PLUS,
    TOK_MINUS,
    TOK_MULTIPLY,
    TOK_DIVIDE,
    TOK_ASSIGN,
    TOK_EQUAL,
    TOK_NOT_EQUAL,
    TOK_LESS,
    TOK_GREATER,
    TOK_LESS_EQUAL,
    TOK_GREATER_EQUAL,
    TOK_LOGICAL_AND,
    TOK_LOGICAL_OR,
    TOK_AMPERSAND,      // Address-of operator
    TOK_ARROW,          // -> operator
    TOK_DOT,            // . operator
    TOK_INCREMENT,      // ++
    TOK_DECREMENT,      // --
    
    // Delimiters
    TOK_SEMICOLON,
    TOK_COMMA,
    TOK_LPAREN,
    TOK_RPAREN,
    TOK_LBRACE,
    TOK_RBRACE,
    TOK_LBRACKET,
    TOK_RBRACKET,
    
    // Special
    TOK_EOF
} TokenType;

// Enhanced variable types
typedef enum {
    VAR_INT,
    VAR_INT_PTR,
    VAR_INT_ARRAY,
    VAR_STRUCT,
    VAR_STRUCT_PTR
} VarType;

typedef struct {
    char name[MAX_TOKEN_LEN];
    char members[10][MAX_TOKEN_LEN];  // Member names
    VarType member_types[10];         // Member types
    int member_count;
    int total_size;                   // Total size in words
} StructDef;

typedef struct {
    char name[MAX_TOKEN_LEN];
    int reg_num;
    VarType type;
    int array_size;      // For arrays
    char struct_type[MAX_TOKEN_LEN];  // For structs
    int memory_offset;   // Memory offset for arrays/structs
} Variable;

typedef struct {
    TokenType type;
    char value[MAX_TOKEN_LEN];
    int line;
    int column;
} Token;

// Global compiler state
typedef struct {
    Token tokens[MAX_TOKENS];
    int count;
    int pos;
    
    Variable variables[MAX_VARIABLES];
    int var_count;
    
    StructDef structs[MAX_STRUCTS];
    int struct_count;
    
    char lines[MAX_CODE_LINES][256];
    int line_count;
    
    int next_reg;
    int label_counter;
    int memory_offset;     // For static allocation
} Compiler;

// Function prototypes
bool parse_declaration(Compiler *comp);
bool parse_array_declaration(Compiler *comp, const char *type_name);
bool parse_struct_declaration(Compiler *comp);
bool parse_pointer_declaration(Compiler *comp, const char *type_name);
int parse_array_access(Compiler *comp, const char *var_name);
int parse_pointer_deref(Compiler *comp, const char *var_name);
int parse_struct_access(Compiler *comp, const char *var_name);

// Enhanced expression parsing
int parse_expression(Compiler *comp);
int parse_primary_expression(Compiler *comp);
int parse_postfix_expression(Compiler *comp);
int parse_unary_expression(Compiler *comp);

// Memory management
void allocate_static_memory(Compiler *comp, Variable *var);
void generate_array_code(Compiler *comp, const char *var_name, int index_reg, int target_reg);
void generate_pointer_code(Compiler *comp, const char *var_name, int target_reg);

// Utility functions
Variable* find_variable(Compiler *comp, const char *name);
StructDef* find_struct(Compiler *comp, const char *name);
int get_next_register(Compiler *comp);
void emit_code(Compiler *comp, const char *format, ...);

// Example enhanced parsing functions
bool parse_array_declaration(Compiler *comp, const char *type_name) {
    // Parse: int arr[size];
    Token name_tok = comp->tokens[comp->pos++];
    
    if (comp->tokens[comp->pos].type != TOK_LBRACKET) {
        return false;
    }
    comp->pos++; // consume '['
    
    Token size_tok = comp->tokens[comp->pos++];
    int array_size = atoi(size_tok.value);
    
    if (comp->tokens[comp->pos].type != TOK_RBRACKET) {
        return false;
    }
    comp->pos++; // consume ']'
    
    // Create variable entry
    Variable *var = &comp->variables[comp->var_count++];
    strcpy(var->name, name_tok.value);
    var->type = VAR_INT_ARRAY;
    var->array_size = array_size;
    var->memory_offset = comp->memory_offset;
    var->reg_num = -1; // Arrays don't use registers directly
    
    // Allocate memory space
    comp->memory_offset += array_size;
    
    // Generate initialization code
    emit_code(comp, "; Array %s[%d] allocated at offset %d", 
              var->name, array_size, var->memory_offset);
    
    return true;
}

void emit_code(Compiler *comp, const char *format, ...) {
    va_list args;
    va_start(args, format);
    vsnprintf(comp->lines[comp->line_count], 256, format, args);
    comp->line_count++;
    va_end(args);
}

// Main compilation function would integrate these features
bool compile_enhanced_c(const char *filename) {
    Compiler comp = {0};
    
    // Initialize compiler state
    comp.next_reg = 2;  // R0, R1 reserved
    comp.memory_offset = 0x10000;  // Start static allocation at 64KB
    
    // Parse and compile with enhanced features
    // ... (implementation would continue here)
    
    return true;
}
