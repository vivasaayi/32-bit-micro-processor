/*
 * Simple C-to-Assembly Compiler for Custom 32-bit RISC Processor
 * 
 * This compiler converts a subset of C code to assembly language for our custom processor.
 * Supports:
 * - Variables and constants
 * - Arithmetic expressions (+, -, *, /)
 * - Function calls and returns
 * - If statements and loops
 * - Arrays and pointers (basic)
 * - Logical operators (&&, ||)
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
#define MAX_LABELS 1000

// Token types
typedef enum {
    // Literals
    TOK_NUMBER,
    TOK_IDENTIFIER,
    TOK_STRING,
    
    // Keywords
    TOK_INT,
    TOK_VOID,
    TOK_STRUCT,     // JVM Enhancement: Add struct support
    TOK_SIZEOF,     // JVM Enhancement: Add sizeof support for malloc
    TOK_IF,
    TOK_ELSE,
    TOK_WHILE,
    TOK_FOR,
    TOK_RETURN,
    
    // Operators
    TOK_PLUS,
    TOK_MINUS,
    TOK_MULTIPLY,
    TOK_DIVIDE,
    TOK_MODULO,     // JVM Enhancement: Add modulo operator for % symbol
    TOK_ASSIGN,
    TOK_EQUAL,
    TOK_NOT_EQUAL,
    TOK_LESS,
    TOK_GREATER,
    TOK_LESS_EQUAL,
    TOK_GREATER_EQUAL,
    TOK_LOGICAL_AND,
    TOK_LOGICAL_OR,
    TOK_AMPERSAND,
    TOK_DOT,        // JVM Enhancement: Add struct member access
    TOK_ARROW,      // JVM Enhancement: Add pointer member access
    
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

typedef struct {
    TokenType type;
    char value[MAX_TOKEN_LEN];
    int line;
    int column;
} Token;

typedef struct {
    char name[MAX_TOKEN_LEN];
    int reg_num;
    char type[32];
    int is_array;       // JVM Enhancement: Track if variable is array
    int array_size;     // JVM Enhancement: Array size
    int is_pointer;     // JVM Enhancement: Track if variable is pointer
    int is_struct;      // JVM Enhancement: Track if variable is struct
    char struct_type[MAX_TOKEN_LEN];  // JVM Enhancement: Struct type name
    int base_address;   // JVM Enhancement: Base address for arrays/structs
} Variable;

// JVM Enhancement: Struct definition
typedef struct {
    char name[MAX_TOKEN_LEN];
    char members[32][MAX_TOKEN_LEN];  // member names
    char member_types[32][32];        // member types  
    int member_offsets[32];           // byte offsets
    int member_count;
    int total_size;                   // total struct size in bytes
} StructDef;

typedef struct {
    Token tokens[MAX_TOKENS];
    int count;
    int pos;
} TokenStream;

typedef struct {
    char lines[MAX_CODE_LINES][256];
    int count;
    Variable variables[MAX_VARIABLES];
    int var_count;
    StructDef structs[MAX_VARIABLES];  // JVM Enhancement: Struct definitions
    int struct_count;                   // JVM Enhancement: Number of structs
    int next_reg;
    int label_counter;
    int heap_ptr;                      // JVM Enhancement: Track heap allocation
} CodeGenerator;

// Global state
TokenStream token_stream;
CodeGenerator codegen;
char *input_text;
int input_pos;
int current_line;
int current_column;

// Function prototypes
void error(const char *msg);
void lexer_error(const char *msg);
void parser_error(const char *msg);
char peek_char(int offset);
char advance_char();
void skip_whitespace();
Token read_number();
Token read_identifier();
Token read_string();
void tokenize(const char *text);
void emit(const char *instruction);
void emit_label(const char *label);
int allocate_register(const char *var_name);
char *generate_label(const char *prefix);
int parse_expression();
void parse_statement();
void parse_function();
void parse_program();
void generate_code();

// Error handling
void error(const char *msg) {
    fprintf(stderr, "Error: %s\n", msg);
    exit(1);
}

void lexer_error(const char *msg) {
    fprintf(stderr, "Lexer error at line %d, col %d: %s\n", current_line, current_column, msg);
    exit(1);
}

void parser_error(const char *msg) {
    if (token_stream.pos < token_stream.count) {
        Token *tok = &token_stream.tokens[token_stream.pos];
        fprintf(stderr, "Parser error at line %d: %s\n", tok->line, msg);
    } else {
        fprintf(stderr, "Parser error: %s\n", msg);
    }
    exit(1);
}

// Character handling
char peek_char(int offset) {
    int pos = input_pos + offset;
    if (pos >= strlen(input_text)) {
        return '\0';
    }
    return input_text[pos];
}

char advance_char() {
    if (input_pos >= strlen(input_text)) {
        return '\0';
    }
    char ch = input_text[input_pos++];
    if (ch == '\n') {
        current_line++;
        current_column = 1;
    } else {
        current_column++;
    }
    return ch;
}

void skip_whitespace() {
    while (isspace(peek_char(0))) {
        advance_char();
    }
}

// Token reading
Token read_number() {
    Token tok;
    tok.type = TOK_NUMBER;
    tok.line = current_line;
    tok.column = current_column;
    
    int i = 0;
    if (peek_char(0) == '0' && (peek_char(1) == 'x' || peek_char(1) == 'X')) {
        tok.value[i++] = advance_char(); // 0
        tok.value[i++] = advance_char(); // x
        while (isxdigit(peek_char(0)) && i < MAX_TOKEN_LEN - 1) {
            tok.value[i++] = advance_char();
        }
    } else {
        while (isdigit(peek_char(0)) && i < MAX_TOKEN_LEN - 1) {
            tok.value[i++] = advance_char();
        }
    }
    tok.value[i] = '\0';
    return tok;
}

Token read_identifier() {
    Token tok;
    tok.line = current_line;
    tok.column = current_column;
    
    int i = 0;
    while ((isalnum(peek_char(0)) || peek_char(0) == '_') && i < MAX_TOKEN_LEN - 1) {
        tok.value[i++] = advance_char();
    }
    tok.value[i] = '\0';
    
    // Check if it's a keyword
    if (strcmp(tok.value, "int") == 0) tok.type = TOK_INT;
    else if (strcmp(tok.value, "void") == 0) tok.type = TOK_VOID;
    else if (strcmp(tok.value, "struct") == 0) tok.type = TOK_STRUCT;  // JVM Enhancement
    else if (strcmp(tok.value, "sizeof") == 0) tok.type = TOK_SIZEOF;  // JVM Enhancement
    else if (strcmp(tok.value, "if") == 0) tok.type = TOK_IF;
    else if (strcmp(tok.value, "else") == 0) tok.type = TOK_ELSE;
    else if (strcmp(tok.value, "while") == 0) tok.type = TOK_WHILE;
    else if (strcmp(tok.value, "for") == 0) tok.type = TOK_FOR;
    else if (strcmp(tok.value, "return") == 0) tok.type = TOK_RETURN;
    else tok.type = TOK_IDENTIFIER;
    
    return tok;
}

Token read_string() {
    Token tok;
    tok.type = TOK_STRING;
    tok.line = current_line;
    tok.column = current_column;
    
    advance_char(); // Skip opening quote
    int i = 0;
    while (peek_char(0) != '"' && peek_char(0) != '\0' && i < MAX_TOKEN_LEN - 1) {
        tok.value[i++] = advance_char();
    }
    if (peek_char(0) == '"') {
        advance_char(); // Skip closing quote
    }
    tok.value[i] = '\0';
    return tok;
}

// Main tokenizer
void tokenize(const char *text) {
    input_text = (char*)text;
    input_pos = 0;
    current_line = 1;
    current_column = 1;
    token_stream.count = 0;
    
    while (input_pos < strlen(text)) {
        skip_whitespace();
        
        if (input_pos >= strlen(text)) break;
        
        char ch = peek_char(0);
        Token tok;
        
        if (isdigit(ch)) {
            tok = read_number();
        } else if (isalpha(ch) || ch == '_') {
            tok = read_identifier();
        } else if (ch == '"') {
            tok = read_string();
        } else {
            tok.line = current_line;
            tok.column = current_column;
            
            switch (ch) {
                case '+':
                    tok.type = TOK_PLUS;
                    strcpy(tok.value, "+");
                    advance_char();
                    break;
                case '-':
                    if (peek_char(1) == '>') {
                        tok.type = TOK_ARROW;
                        strcpy(tok.value, "->");
                        advance_char(); advance_char();
                    } else {
                        tok.type = TOK_MINUS;
                        strcpy(tok.value, "-");
                        advance_char();
                    }
                    break;
                case '*':
                    tok.type = TOK_MULTIPLY;
                    strcpy(tok.value, "*");
                    advance_char();
                    break;
                case '/':
                    if (peek_char(1) == '/') {
                        // Skip single-line comment
                        while (peek_char(0) != '\n' && peek_char(0) != '\0') {
                            advance_char();
                        }
                        continue;
                    } else if (peek_char(1) == '*') {
                        // Skip multi-line comment
                        advance_char(); advance_char();
                        while (!(peek_char(0) == '*' && peek_char(1) == '/') && peek_char(0) != '\0') {
                            advance_char();
                        }
                        if (peek_char(0) == '*') {
                            advance_char(); advance_char();
                        }
                        continue;
                    } else {
                        tok.type = TOK_DIVIDE;
                        strcpy(tok.value, "/");
                        advance_char();
                    }
                    break;
                case '=':
                    if (peek_char(1) == '=') {
                        tok.type = TOK_EQUAL;
                        strcpy(tok.value, "==");
                        advance_char(); advance_char();
                    } else {
                        tok.type = TOK_ASSIGN;
                        strcpy(tok.value, "=");
                        advance_char();
                    }
                    break;
                case '!':
                    if (peek_char(1) == '=') {
                        tok.type = TOK_NOT_EQUAL;
                        strcpy(tok.value, "!=");
                        advance_char(); advance_char();
                    } else {
                        lexer_error("Unexpected character");
                    }
                    break;
                case '<':
                    if (peek_char(1) == '=') {
                        tok.type = TOK_LESS_EQUAL;
                        strcpy(tok.value, "<=");
                        advance_char(); advance_char();
                    } else {
                        tok.type = TOK_LESS;
                        strcpy(tok.value, "<");
                        advance_char();
                    }
                    break;
                case '>':
                    if (peek_char(1) == '=') {
                        tok.type = TOK_GREATER_EQUAL;
                        strcpy(tok.value, ">=");
                        advance_char(); advance_char();
                    } else {
                        tok.type = TOK_GREATER;
                        strcpy(tok.value, ">");
                        advance_char();
                    }
                    break;
                case '&':
                    if (peek_char(1) == '&') {
                        tok.type = TOK_LOGICAL_AND;
                        strcpy(tok.value, "&&");
                        advance_char(); advance_char();
                    } else {
                        tok.type = TOK_AMPERSAND;
                        strcpy(tok.value, "&");
                        advance_char();
                    }
                    break;
                case '|':
                    if (peek_char(1) == '|') {
                        tok.type = TOK_LOGICAL_OR;
                        strcpy(tok.value, "||");
                        advance_char(); advance_char();
                    } else {
                        lexer_error("Unsupported character");
                    }
                    break;
                case ';':
                    tok.type = TOK_SEMICOLON;
                    strcpy(tok.value, ";");
                    advance_char();
                    break;
                case ',':
                    tok.type = TOK_COMMA;
                    strcpy(tok.value, ",");
                    advance_char();
                    break;
                case '(':
                    tok.type = TOK_LPAREN;
                    strcpy(tok.value, "(");
                    advance_char();
                    break;
                case ')':
                    tok.type = TOK_RPAREN;
                    strcpy(tok.value, ")");
                    advance_char();
                    break;
                case '{':
                    tok.type = TOK_LBRACE;
                    strcpy(tok.value, "{");
                    advance_char();
                    break;
                case '}':
                    tok.type = TOK_RBRACE;
                    strcpy(tok.value, "}");
                    advance_char();
                    break;
                case '[':
                    tok.type = TOK_LBRACKET;
                    strcpy(tok.value, "[");
                    advance_char();
                    break;
                case ']':
                    tok.type = TOK_RBRACKET;
                    strcpy(tok.value, "]");
                    advance_char();
                    break;
                // JVM Enhancement: Add modulo operator lexing
                case '%':
                    tok.type = TOK_MODULO;
                    strcpy(tok.value, "%");
                    advance_char();
                    break;
                // JVM Enhancement: Add struct member access
                case '.':
                    tok.type = TOK_DOT;
                    strcpy(tok.value, ".");
                    advance_char();
                    break;
                default:
                    lexer_error("Unexpected character");
            }
        }
        
        if (token_stream.count < MAX_TOKENS) {
            token_stream.tokens[token_stream.count++] = tok;
        }
    }
    
    // Add EOF token
    Token eof_tok;
    eof_tok.type = TOK_EOF;
    strcpy(eof_tok.value, "");
    eof_tok.line = current_line;
    eof_tok.column = current_column;
    token_stream.tokens[token_stream.count++] = eof_tok;
}

// Code generation functions
void emit(const char *instruction) {
    if (codegen.count < MAX_CODE_LINES) {
        strcpy(codegen.lines[codegen.count++], instruction);
    }
}

void emit_label(const char *label) {
    char line[256];
    snprintf(line, sizeof(line), "%s:", label);
    emit(line);
}

int allocate_register(const char *var_name) {
    // Check if variable already has a register
    for (int i = 0; i < codegen.var_count; i++) {
        if (strcmp(codegen.variables[i].name, var_name) == 0) {
            return codegen.variables[i].reg_num;
        }
    }
    
    // Allocate new register
    if (codegen.next_reg >= 30) {
        error("Out of registers");
    }
    
    Variable var;
    strcpy(var.name, var_name);
    var.reg_num = codegen.next_reg++;
    strcpy(var.type, "int");
    var.is_array = 0;        // JVM Enhancement: Initialize array flag
    var.array_size = 0;      // JVM Enhancement: Initialize array size
    var.is_pointer = 0;      // JVM Enhancement: Initialize pointer flag
    var.is_struct = 0;       // JVM Enhancement: Initialize struct flag
    strcpy(var.struct_type, ""); // JVM Enhancement: Initialize struct type
    var.base_address = 0;    // JVM Enhancement: Initialize base address
    
    codegen.variables[codegen.var_count++] = var;
    return var.reg_num;
}

// JVM Enhancement: Allocate array with heap memory
int allocate_array(const char *var_name, int size, const char *type) {
    Variable var;
    strcpy(var.name, var_name);
    var.reg_num = codegen.next_reg++;
    strcpy(var.type, type);
    var.is_array = 1;
    var.array_size = size;
    var.is_pointer = 1;  // Arrays are implemented as pointers
    var.is_struct = 0;
    strcpy(var.struct_type, "");
    var.base_address = codegen.heap_ptr;  // Allocate on heap
    
    // Emit code to allocate array on heap
    char instr[256];
    snprintf(instr, sizeof(instr), "LOADI R%d, #%d", var.reg_num, var.base_address);
    emit(instr);
    
    // Update heap pointer (assuming 4 bytes per element)
    codegen.heap_ptr += size * 4;
    
    codegen.variables[codegen.var_count++] = var;
    return var.reg_num;
}

// JVM Enhancement: Find struct definition
StructDef* find_struct(const char *name) {
    for (int i = 0; i < codegen.struct_count; i++) {
        if (strcmp(codegen.structs[i].name, name) == 0) {
            return &codegen.structs[i];
        }
    }
    return NULL;
}

char *generate_label(const char *prefix) {
    static char labels[MAX_LABELS][64];
    static int current_label = 0;
    
    if (current_label >= MAX_LABELS) {
        error("Too many labels");
    }
    
    snprintf(labels[current_label], 64, "%s%d", prefix, codegen.label_counter++);
    return labels[current_label++];
}

// Parser helper functions
Token *current_token() {
    if (token_stream.pos >= token_stream.count) {
        return &token_stream.tokens[token_stream.count - 1]; // EOF token
    }
    return &token_stream.tokens[token_stream.pos];
}

Token *advance_token() {
    Token *tok = current_token();
    if (tok->type != TOK_EOF) {
        token_stream.pos++;
    }
    return tok;
}

Token *expect_token(TokenType type) {
    Token *tok = current_token();
    if (tok->type != type) {
        parser_error("Unexpected token");
    }
    return advance_token();
}

// Expression parsing - returns register number containing result
int parse_primary() {
    Token *tok = current_token();
    
    if (tok->type == TOK_NUMBER) {
        advance_token();
        int reg = codegen.next_reg++;
        if (codegen.next_reg >= 30) codegen.next_reg = 1; // Simple register recycling
        
        char instr[256];
        snprintf(instr, sizeof(instr), "LOADI R%d, #%s", reg, tok->value);
        emit(instr);
        return reg;
    }
    
    // JVM Enhancement: Handle sizeof operator
    if (tok->type == TOK_SIZEOF) {
        advance_token();
        expect_token(TOK_LPAREN);
        Token *type_tok = current_token();
        if (type_tok->type == TOK_STRUCT) {
            advance_token();
            Token *struct_name_tok = expect_token(TOK_IDENTIFIER);
            StructDef *struct_def = find_struct(struct_name_tok->value);
            if (!struct_def) {
                parser_error("Unknown struct type");
            }
            expect_token(TOK_RPAREN);
            
            int reg = codegen.next_reg++;
            if (codegen.next_reg >= 30) codegen.next_reg = 1;
            char instr[256];
            snprintf(instr, sizeof(instr), "LOADI R%d, #%d", reg, struct_def->total_size);
            emit(instr);
            return reg;
        } else if (type_tok->type == TOK_INT) {
            advance_token();
            expect_token(TOK_RPAREN);
            
            int reg = codegen.next_reg++;
            if (codegen.next_reg >= 30) codegen.next_reg = 1;
            char instr[256];
            snprintf(instr, sizeof(instr), "LOADI R%d, #4", reg);  // int is 4 bytes
            emit(instr);
            return reg;
        }
        parser_error("Unsupported sizeof operand");
    }
    
    if (tok->type == TOK_IDENTIFIER) {
        advance_token();
        char var_name[MAX_TOKEN_LEN];
        strcpy(var_name, tok->value);
        
        if (current_token()->type == TOK_LPAREN) {
            // Function call
            advance_token(); // consume '('
            
            // JVM Enhancement: Handle function calls with arguments
            int arg_count = 0;
            int arg_regs[16];  // Support up to 16 arguments
            
            while (current_token()->type != TOK_RPAREN) {
                if (arg_count > 0) {
                    expect_token(TOK_COMMA);
                }
                arg_regs[arg_count++] = parse_expression();
                if (arg_count >= 16) {
                    parser_error("Too many function arguments");
                }
            }
            expect_token(TOK_RPAREN);
            
            // JVM Enhancement: Handle special functions like malloc and free
            if (strcmp(var_name, "malloc") == 0) {
                if (arg_count != 1) {
                    parser_error("malloc requires exactly one argument");
                }
                
                // Emit malloc implementation
                int result_reg = codegen.next_reg++;
                if (codegen.next_reg >= 30) codegen.next_reg = 1;
                
                char instr[256];
                snprintf(instr, sizeof(instr), "MOVE R%d, R29", result_reg);  // Current heap pointer
                emit(instr);
                snprintf(instr, sizeof(instr), "ADD R29, R29, R%d", arg_regs[0]);  // Update heap pointer
                emit(instr);
                
                return result_reg;
            } else if (strcmp(var_name, "free") == 0) {
                if (arg_count != 1) {
                    parser_error("free requires exactly one argument");
                }
                
                // For simplicity, free is a no-op in our implementation
                // In a real implementation, we'd track allocated blocks
                emit("; free() - no-op in simple implementation");
                
                int result_reg = codegen.next_reg++;
                if (codegen.next_reg >= 30) codegen.next_reg = 1;
                return result_reg;
            }
            
            // Emit argument setup code
            for (int i = 0; i < arg_count; i++) {
                char instr[256];
                snprintf(instr, sizeof(instr), "MOVE R%d, R%d", i + 2, arg_regs[i]);  // R2, R3, etc.
                emit(instr);
            }
            
            char instr[256];
            snprintf(instr, sizeof(instr), "CALL %s", var_name);
            emit(instr);
            return 1; // Result in R1
        } else if (current_token()->type == TOK_LBRACKET) {
            // JVM Enhancement: Array indexing
            advance_token(); // consume '['
            int index_reg = parse_expression();
            expect_token(TOK_RBRACKET);
            
            // Find the array variable
            Variable *var = NULL;
            for (int i = 0; i < codegen.var_count; i++) {
                if (strcmp(codegen.variables[i].name, var_name) == 0) {
                    var = &codegen.variables[i];
                    break;
                }
            }
            
            if (!var || !var->is_array) {
                parser_error("Variable is not an array");
            }
            
            // Calculate address: base + index * element_size
            int addr_reg = codegen.next_reg++;
            int elem_size_reg = codegen.next_reg++;
            int result_reg = codegen.next_reg++;
            if (codegen.next_reg >= 30) codegen.next_reg = 1;
            
            char instr[256];
            int element_size = 4;  // Default to 4 bytes for int
            
            if (var->is_struct) {
                // For struct arrays, calculate struct size
                StructDef *struct_def = find_struct(var->struct_type);
                if (struct_def) {
                    element_size = struct_def->total_size;
                }
            }
            
            snprintf(instr, sizeof(instr), "LOADI R%d, #%d", elem_size_reg, element_size);
            emit(instr);
            snprintf(instr, sizeof(instr), "MUL R%d, R%d, R%d", addr_reg, index_reg, elem_size_reg);
            emit(instr);
            snprintf(instr, sizeof(instr), "ADD R%d, R%d, R%d", addr_reg, var->reg_num, addr_reg);
            emit(instr);
            
            // Check if there's a struct member access after array index
            if (current_token()->type == TOK_DOT) {
                advance_token(); // consume '.'
                Token *member_tok = expect_token(TOK_IDENTIFIER);
                
                if (!var->is_struct) {
                    parser_error("Array element is not a struct");
                }
                
                StructDef *struct_def = find_struct(var->struct_type);
                if (!struct_def) {
                    parser_error("Unknown struct type");
                }
                
                // Find member offset
                int member_offset = -1;
                for (int i = 0; i < struct_def->member_count; i++) {
                    if (strcmp(struct_def->members[i], member_tok->value) == 0) {
                        member_offset = struct_def->member_offsets[i];
                        break;
                    }
                }
                
                if (member_offset == -1) {
                    parser_error("Unknown struct member");
                }
                
                // Load struct member: address + member_offset
                snprintf(instr, sizeof(instr), "LOAD R%d, R%d, #%d", result_reg, addr_reg, member_offset);
                emit(instr);
            } else {
                // Just load the array element
                snprintf(instr, sizeof(instr), "LOAD R%d, R%d, #0", result_reg, addr_reg);
                emit(instr);
            }
            
            return result_reg;
        } else if (current_token()->type == TOK_DOT) {
            // JVM Enhancement: Struct member access
            advance_token(); // consume '.'
            Token *member_tok = expect_token(TOK_IDENTIFIER);
            
            // Find the struct variable
            Variable *var = NULL;
            for (int i = 0; i < codegen.var_count; i++) {
                if (strcmp(codegen.variables[i].name, var_name) == 0) {
                    var = &codegen.variables[i];
                    break;
                }
            }
            
            if (!var || !var->is_struct) {
                parser_error("Variable is not a struct");
            }
            
            StructDef *struct_def = find_struct(var->struct_type);
            if (!struct_def) {
                parser_error("Unknown struct type");
            }
            
            // Find member offset
            int member_offset = -1;
            for (int i = 0; i < struct_def->member_count; i++) {
                if (strcmp(struct_def->members[i], member_tok->value) == 0) {
                    member_offset = struct_def->member_offsets[i];
                    break;
                }
            }
            
            if (member_offset == -1) {
                parser_error("Unknown struct member");
            }
            
            // Generate code to access member
            int result_reg = codegen.next_reg++;
            if (codegen.next_reg >= 30) codegen.next_reg = 1;
            
            char instr[256];
            snprintf(instr, sizeof(instr), "LOAD R%d, R%d, #%d", result_reg, var->reg_num, member_offset);
            emit(instr);
            
            return result_reg;
        } else {
            // Simple variable
            int reg = allocate_register(var_name);
            return reg;
        }
    }
    
    if (tok->type == TOK_LPAREN) {
        advance_token();
        int reg = parse_expression();
        expect_token(TOK_RPAREN);
        return reg;
    }
    
    parser_error("Unexpected token in expression");
    return 0;
}

int parse_multiplication() {
    int left_reg = parse_primary();
    
    while (current_token()->type == TOK_MULTIPLY || current_token()->type == TOK_DIVIDE || current_token()->type == TOK_MODULO) {
        Token *op = advance_token();
        int right_reg = parse_primary();
        int result_reg = codegen.next_reg++;
        if (codegen.next_reg >= 30) codegen.next_reg = 1;
        
        char instr[256];
        if (op->type == TOK_MULTIPLY) {
            snprintf(instr, sizeof(instr), "MUL R%d, R%d, R%d", result_reg, left_reg, right_reg);
        } else if (op->type == TOK_DIVIDE) {
            snprintf(instr, sizeof(instr), "DIV R%d, R%d, R%d", result_reg, left_reg, right_reg);
        } else { // TOK_MODULO - JVM Enhancement
            snprintf(instr, sizeof(instr), "MOD R%d, R%d, R%d", result_reg, left_reg, right_reg);
        }
        emit(instr);
        left_reg = result_reg;
    }
    
    return left_reg;
}

int parse_addition() {
    int left_reg = parse_multiplication();
    
    while (current_token()->type == TOK_PLUS || current_token()->type == TOK_MINUS) {
        Token *op = advance_token();
        int right_reg = parse_multiplication();
        int result_reg = codegen.next_reg++;
        if (codegen.next_reg >= 30) codegen.next_reg = 1;
        
        char instr[256];
        if (op->type == TOK_PLUS) {
            snprintf(instr, sizeof(instr), "ADD R%d, R%d, R%d", result_reg, left_reg, right_reg);
        } else {
            snprintf(instr, sizeof(instr), "SUB R%d, R%d, R%d", result_reg, left_reg, right_reg);
        }
        emit(instr);
        left_reg = result_reg;
    }
    
    return left_reg;
}

int parse_comparison() {
    int left_reg = parse_addition();
    
    while (current_token()->type == TOK_LESS || current_token()->type == TOK_GREATER ||
           current_token()->type == TOK_LESS_EQUAL || current_token()->type == TOK_GREATER_EQUAL) {
        Token *op = advance_token();
        int right_reg = parse_addition();
        int result_reg = codegen.next_reg++;
        if (codegen.next_reg >= 30) codegen.next_reg = 1;
        
        char instr[256];
        char *less_label = generate_label("LESS");
        char *not_less_label = generate_label("NOT_LESS"); 
        char *end_label = generate_label("END_CMP");
        
        if (op->type == TOK_LESS) {
            snprintf(instr, sizeof(instr), "SUB R%d, R%d, R%d", result_reg, left_reg, right_reg);
            emit(instr);
            snprintf(instr, sizeof(instr), "JN %s", less_label);
            emit(instr);
            snprintf(instr, sizeof(instr), "JMP %s", not_less_label);
            emit(instr);
            emit_label(less_label);
            snprintf(instr, sizeof(instr), "LOADI R%d, #1", result_reg);
            emit(instr);
            snprintf(instr, sizeof(instr), "JMP %s", end_label);
            emit(instr);
            emit_label(not_less_label);
            snprintf(instr, sizeof(instr), "LOADI R%d, #0", result_reg);
            emit(instr);
            emit_label(end_label);
        }
        // Add other comparison operators as needed
        
        left_reg = result_reg;
    }
    
    return left_reg;
}

int parse_equality() {
    int left_reg = parse_comparison();
    
    while (current_token()->type == TOK_EQUAL || current_token()->type == TOK_NOT_EQUAL) {
        Token *op = advance_token();
        int right_reg = parse_comparison();
        int result_reg = codegen.next_reg++;
        if (codegen.next_reg >= 30) codegen.next_reg = 1;
        
        char instr[256];
        char *equal_label = generate_label("EQUAL");
        char *not_equal_label = generate_label("NOT_EQUAL");
        char *end_label = generate_label("END_CMP");
        
        snprintf(instr, sizeof(instr), "SUB R%d, R%d, R%d", result_reg, left_reg, right_reg);
        emit(instr);
        
        if (op->type == TOK_EQUAL) {
            snprintf(instr, sizeof(instr), "JZ %s", equal_label);
            emit(instr);
            snprintf(instr, sizeof(instr), "JMP %s", not_equal_label);
            emit(instr);
            emit_label(equal_label);
            snprintf(instr, sizeof(instr), "LOADI R%d, #1", result_reg);
            emit(instr);
            snprintf(instr, sizeof(instr), "JMP %s", end_label);
            emit(instr);
            emit_label(not_equal_label);
            snprintf(instr, sizeof(instr), "LOADI R%d, #0", result_reg);
            emit(instr);
            emit_label(end_label);
        } else { // NOT_EQUAL
            snprintf(instr, sizeof(instr), "JZ %s", not_equal_label);
            emit(instr);
            snprintf(instr, sizeof(instr), "JMP %s", equal_label);
            emit(instr);
            emit_label(equal_label);
            snprintf(instr, sizeof(instr), "LOADI R%d, #1", result_reg);
            emit(instr);
            snprintf(instr, sizeof(instr), "JMP %s", end_label);
            emit(instr);
            emit_label(not_equal_label);
            snprintf(instr, sizeof(instr), "LOADI R%d, #0", result_reg);
            emit(instr);
            emit_label(end_label);
        }
        
        left_reg = result_reg;
    }
    
    return left_reg;
}

int parse_logical_and() {
    int left_reg = parse_equality();
    
    while (current_token()->type == TOK_LOGICAL_AND) {
        advance_token();
        int right_reg = parse_equality();
        int result_reg = codegen.next_reg++;
        if (codegen.next_reg >= 30) codegen.next_reg = 1;
        
        char instr[256];
        char *false_label = generate_label("FALSE");
        char *true_label = generate_label("TRUE");
        char *end_label = generate_label("END_AND");
        
        // If left is false, result is false
        snprintf(instr, sizeof(instr), "CMP R%d, R0", left_reg);
        emit(instr);
        snprintf(instr, sizeof(instr), "JZ %s", false_label);
        emit(instr);
        
        // If right is false, result is false
        snprintf(instr, sizeof(instr), "CMP R%d, R0", right_reg);
        emit(instr);
        snprintf(instr, sizeof(instr), "JZ %s", false_label);
        emit(instr);
        
        // Both are true
        snprintf(instr, sizeof(instr), "JMP %s", true_label);
        emit(instr);
        
        emit_label(false_label);
        snprintf(instr, sizeof(instr), "LOADI R%d, #0", result_reg);
        emit(instr);
        snprintf(instr, sizeof(instr), "JMP %s", end_label);
        emit(instr);
        
        emit_label(true_label);
        snprintf(instr, sizeof(instr), "LOADI R%d, #1", result_reg);
        emit(instr);
        
        emit_label(end_label);
        left_reg = result_reg;
    }
    
    return left_reg;
}

int parse_logical_or() {
    int left_reg = parse_logical_and();
    
    while (current_token()->type == TOK_LOGICAL_OR) {
        advance_token();
        int right_reg = parse_logical_and();
        int result_reg = codegen.next_reg++;
        if (codegen.next_reg >= 30) codegen.next_reg = 1;
        
        char instr[256];
        char *true_label = generate_label("TRUE");
        char *false_label = generate_label("FALSE");
        char *end_label = generate_label("END_OR");
        
        // If left is true, result is true
        snprintf(instr, sizeof(instr), "CMP R%d, R0", left_reg);
        emit(instr);
        snprintf(instr, sizeof(instr), "JNZ %s", true_label);
        emit(instr);
        
        // If right is true, result is true
        snprintf(instr, sizeof(instr), "CMP R%d, R0", right_reg);
        emit(instr);
        snprintf(instr, sizeof(instr), "JNZ %s", true_label);
        emit(instr);
        
        // Both are false
        snprintf(instr, sizeof(instr), "JMP %s", false_label);
        emit(instr);
        
        emit_label(true_label);
        snprintf(instr, sizeof(instr), "LOADI R%d, #1", result_reg);
        emit(instr);
        snprintf(instr, sizeof(instr), "JMP %s", end_label);
        emit(instr);
        
        emit_label(false_label);
        snprintf(instr, sizeof(instr), "LOADI R%d, #0", result_reg);
        emit(instr);
        
        emit_label(end_label);
        left_reg = result_reg;
    }
    
    return left_reg;
}

int parse_expression() {
    return parse_logical_or();
}

// JVM Enhancement: Parse struct definition
void parse_struct_definition() {
    expect_token(TOK_STRUCT);
    Token *name_tok = expect_token(TOK_IDENTIFIER);
    expect_token(TOK_LBRACE);
    
    StructDef struct_def;
    strcpy(struct_def.name, name_tok->value);
    struct_def.member_count = 0;
    struct_def.total_size = 0;
    
    // Parse struct members
    while (current_token()->type != TOK_RBRACE) {
        Token *type_tok = current_token();
        if (type_tok->type == TOK_INT) {
            advance_token();
            Token *member_tok = expect_token(TOK_IDENTIFIER);
            
            // Handle array members
            int array_size = 1;
            if (current_token()->type == TOK_LBRACKET) {
                advance_token();
                Token *size_tok = expect_token(TOK_NUMBER);
                array_size = atoi(size_tok->value);
                expect_token(TOK_RBRACKET);
            }
            
            expect_token(TOK_SEMICOLON);
            
            strcpy(struct_def.members[struct_def.member_count], member_tok->value);
            strcpy(struct_def.member_types[struct_def.member_count], "int");
            struct_def.member_offsets[struct_def.member_count] = struct_def.total_size;
            struct_def.member_count++;
            
            struct_def.total_size += 4 * array_size;  // 4 bytes per int
        } else if (type_tok->type == TOK_STRUCT) {
            advance_token();
            Token *struct_type_tok = expect_token(TOK_IDENTIFIER);
            Token *member_tok = expect_token(TOK_IDENTIFIER);
            expect_token(TOK_SEMICOLON);
            
            // Find the referenced struct to get its size
            StructDef *ref_struct = find_struct(struct_type_tok->value);
            if (!ref_struct) {
                parser_error("Unknown struct type");
            }
            
            strcpy(struct_def.members[struct_def.member_count], member_tok->value);
            snprintf(struct_def.member_types[struct_def.member_count], 32, "struct %s", struct_type_tok->value);
            struct_def.member_offsets[struct_def.member_count] = struct_def.total_size;
            struct_def.member_count++;
            
            struct_def.total_size += ref_struct->total_size;
        } else {
            parser_error("Unsupported struct member type");
        }
    }
    
    expect_token(TOK_RBRACE);
    expect_token(TOK_SEMICOLON);
    
    // Add struct definition to global list
    codegen.structs[codegen.struct_count++] = struct_def;
}

// Statement parsing
void parse_var_declaration() {
    Token *type_tok = current_token();
    
    if (type_tok->type == TOK_INT) {
        expect_token(TOK_INT);

        bool is_pointer = false;
        if (current_token()->type == TOK_MULTIPLY) {
            is_pointer = true;
            advance_token();
        }
        
        Token *name_tok = expect_token(TOK_IDENTIFIER);
        
        // JVM Enhancement: Handle array declarations
        bool is_array = false;
        int array_size = 0;
        if (current_token()->type == TOK_LBRACKET) {
            is_array = true;
            advance_token();
            if (current_token()->type == TOK_NUMBER) {
                Token *size_tok = advance_token();
                array_size = atoi(size_tok->value);
            } else {
                array_size = 1;  // Dynamic array, size unknown
            }
            expect_token(TOK_RBRACKET);
        }
        
        int reg;
        if (is_array) {
            reg = allocate_array(name_tok->value, array_size, "int");
        } else {
            reg = allocate_register(name_tok->value);
            // Update variable properties
            for (int i = 0; i < codegen.var_count; i++) {
                if (strcmp(codegen.variables[i].name, name_tok->value) == 0) {
                    codegen.variables[i].is_pointer = is_pointer;
                    break;
                }
            }
        }
        
        if (current_token()->type == TOK_ASSIGN) {
            advance_token();
            
            if (is_pointer && current_token()->type == TOK_AMPERSAND) {
                advance_token(); // consume '&'
                Token *addr_of_var_tok = expect_token(TOK_IDENTIFIER);
                int addr_of_var_reg = allocate_register(addr_of_var_tok->value);
                // HACK: Assume the register for the variable holds the address we want.
                char instr[256];
                snprintf(instr, sizeof(instr), "MOVE R%d, R%d", reg, addr_of_var_reg);
                emit(instr);
            } else {
                int value_reg = parse_expression();
                
                if (value_reg != reg) {
                    char instr[256];
                    snprintf(instr, sizeof(instr), "MOVE R%d, R%d", reg, value_reg);
                    emit(instr);
                }
            }
        } else if (!is_array) {
            // Initialize to 0 (arrays are already allocated)
            char instr[256];
            snprintf(instr, sizeof(instr), "MOVE R%d, R0", reg);
            emit(instr);
        }
        
        expect_token(TOK_SEMICOLON);
    } else if (type_tok->type == TOK_STRUCT) {
        // JVM Enhancement: Handle struct variable declarations
        advance_token();
        Token *struct_type_tok = expect_token(TOK_IDENTIFIER);
        Token *var_name_tok = expect_token(TOK_IDENTIFIER);
        
        StructDef *struct_def = find_struct(struct_type_tok->value);
        if (!struct_def) {
            parser_error("Unknown struct type");
        }
        
        // JVM Enhancement: Handle struct arrays
        bool is_array = false;
        int array_size = 1;
        if (current_token()->type == TOK_LBRACKET) {
            is_array = true;
            advance_token();
            if (current_token()->type == TOK_NUMBER) {
                Token *size_tok = advance_token();
                array_size = atoi(size_tok->value);
            }
            expect_token(TOK_RBRACKET);
        }
        
        // Allocate struct variable
        Variable var;
        strcpy(var.name, var_name_tok->value);
        var.reg_num = codegen.next_reg++;
        strcpy(var.type, "struct");
        var.is_array = is_array;
        var.array_size = array_size;
        var.is_pointer = is_array;  // Arrays are pointers to first element
        var.is_struct = 1;
        strcpy(var.struct_type, struct_type_tok->value);
        var.base_address = codegen.heap_ptr;  // Allocate on heap
        
        // Emit code to allocate struct(s) on heap
        char instr[256];
        snprintf(instr, sizeof(instr), "LOADI R%d, #%d", var.reg_num, var.base_address);
        emit(instr);
        
        // Update heap pointer
        int total_size = struct_def->total_size * array_size;
        codegen.heap_ptr += total_size;
        
        codegen.variables[codegen.var_count++] = var;
        
        expect_token(TOK_SEMICOLON);
    } else {
        parser_error("Expected type in variable declaration");
    }
}

void parse_assignment() {
    bool is_deref = false;
    if (current_token()->type == TOK_MULTIPLY) {
        is_deref = true;
        advance_token();
    }

    Token *name_tok = expect_token(TOK_IDENTIFIER);
    char var_name[MAX_TOKEN_LEN];
    strcpy(var_name, name_tok->value);
    
    // JVM Enhancement: Handle array indexing in assignment
    bool is_array_access = false;
    int index_reg = 0;
    if (current_token()->type == TOK_LBRACKET) {
        is_array_access = true;
        advance_token();
        index_reg = parse_expression();
        expect_token(TOK_RBRACKET);
    }
    
    // JVM Enhancement: Handle struct member access in assignment
    bool is_struct_access = false;
    char member_name[MAX_TOKEN_LEN];
    int member_offset = 0;
    bool is_struct_array_member = false;
    
    if (current_token()->type == TOK_DOT) {
        is_struct_access = true;
        advance_token();
        Token *member_tok = expect_token(TOK_IDENTIFIER);
        strcpy(member_name, member_tok->value);
        
        // Check if this struct member is an array: struct.array[index]
        if (current_token()->type == TOK_LBRACKET) {
            is_struct_array_member = true;
            advance_token();
            index_reg = parse_expression();
            expect_token(TOK_RBRACKET);
        }
        
        // Find the struct variable
        Variable *var = NULL;
        for (int i = 0; i < codegen.var_count; i++) {
            if (strcmp(codegen.variables[i].name, var_name) == 0) {
                var = &codegen.variables[i];
                break;
            }
        }
        
        if (!var || (!var->is_struct && !is_array_access)) {
            parser_error("Variable is not a struct");
        }
        
        StructDef *struct_def = find_struct(var->struct_type);
        if (!struct_def) {
            parser_error("Unknown struct type");
        }
        
        // Find member offset
        member_offset = -1;
        for (int i = 0; i < struct_def->member_count; i++) {
            if (strcmp(struct_def->members[i], member_name) == 0) {
                member_offset = struct_def->member_offsets[i];
                break;
            }
        }
        
        if (member_offset == -1) {
            parser_error("Unknown struct member");
        }
    }
    
    expect_token(TOK_ASSIGN);
    int value_reg = parse_expression();
    
    int var_reg = allocate_register(var_name);

    if (is_deref) {
        char instr[256];
        snprintf(instr, sizeof(instr), "STORE R%d, R%d, #0", value_reg, var_reg);
        emit(instr);
    } else if (is_array_access) {
        // Array assignment: arr[index] = value or arr[index].member = value
        Variable *var = NULL;
        for (int i = 0; i < codegen.var_count; i++) {
            if (strcmp(codegen.variables[i].name, var_name) == 0) {
                var = &codegen.variables[i];
                break;
            }
        }
        
        if (!var || !var->is_array) {
            parser_error("Variable is not an array");
        }
        
        // Calculate address: base + index * element_size
        int addr_reg = codegen.next_reg++;
        int elem_size_reg = codegen.next_reg++;
        if (codegen.next_reg >= 30) codegen.next_reg = 1;
        
        char instr[256];
        int element_size = 4;  // Default to 4 bytes for int
        
        if (var->is_struct) {
            // For struct arrays, calculate struct size
            StructDef *struct_def = find_struct(var->struct_type);
            if (struct_def) {
                element_size = struct_def->total_size;
            }
        }
        
        snprintf(instr, sizeof(instr), "LOADI R%d, #%d", elem_size_reg, element_size);
        emit(instr);
        snprintf(instr, sizeof(instr), "MUL R%d, R%d, R%d", addr_reg, index_reg, elem_size_reg);
        emit(instr);
        snprintf(instr, sizeof(instr), "ADD R%d, R%d, R%d", addr_reg, var->reg_num, addr_reg);
        emit(instr);
        
        if (is_struct_access) {
            // Store to struct member: address + member_offset
            snprintf(instr, sizeof(instr), "STORE R%d, R%d, #%d", value_reg, addr_reg, member_offset);
        } else {
            // Store to array element directly
            snprintf(instr, sizeof(instr), "STORE R%d, R%d, #0", value_reg, addr_reg);
        }
        emit(instr);
    } else if (is_struct_access) {
        // Struct member assignment: struct.member = value OR struct.array[index] = value
        if (is_struct_array_member) {
            // Handle struct.array[index] = value
            // Calculate base address of struct member (which is an array)
            int struct_member_addr_reg = codegen.next_reg++;
            int elem_size_reg = codegen.next_reg++;
            int final_addr_reg = codegen.next_reg++;
            if (codegen.next_reg >= 30) codegen.next_reg = 1;
            
            // Find the struct variable
            Variable *var = NULL;
            for (int i = 0; i < codegen.var_count; i++) {
                if (strcmp(codegen.variables[i].name, var_name) == 0) {
                    var = &codegen.variables[i];
                    break;
                }
            }
            
            char instr[256];
            // Get address of struct member: struct_base + member_offset
            snprintf(instr, sizeof(instr), "ADD R%d, R%d, #%d", struct_member_addr_reg, var->reg_num, member_offset);
            emit(instr);
            
            // Calculate array element address: member_base + index * element_size
            snprintf(instr, sizeof(instr), "LOADI R%d, #4", elem_size_reg);  // 4 bytes per int
            emit(instr);
            snprintf(instr, sizeof(instr), "MUL R%d, R%d, R%d", final_addr_reg, index_reg, elem_size_reg);
            emit(instr);
            snprintf(instr, sizeof(instr), "ADD R%d, R%d, R%d", final_addr_reg, struct_member_addr_reg, final_addr_reg);
            emit(instr);
            
            // Store value at calculated address
            snprintf(instr, sizeof(instr), "STORE R%d, R%d, #0", value_reg, final_addr_reg);
            emit(instr);
        } else {
            // Simple struct member assignment: struct.member = value
            char instr[256];
            snprintf(instr, sizeof(instr), "STORE R%d, R%d, #%d", value_reg, var_reg, member_offset);
            emit(instr);
        }
    } else {
        // Simple variable assignment
        if (value_reg != var_reg) {
            char instr[256];
            snprintf(instr, sizeof(instr), "MOVE R%d, R%d", var_reg, value_reg);
            emit(instr);
        }
    }
    
    expect_token(TOK_SEMICOLON);
}

void parse_if_statement() {
    expect_token(TOK_IF);
    expect_token(TOK_LPAREN);
    int cond_reg = parse_expression();
    expect_token(TOK_RPAREN);
    
    char *else_label = generate_label("ELSE");
    char *end_label = generate_label("END_IF");
    
    char instr[256];
    snprintf(instr, sizeof(instr), "CMP R%d, R0", cond_reg);
    emit(instr);
    snprintf(instr, sizeof(instr), "JZ %s", else_label);
    emit(instr);
    
    // Parse then block
    expect_token(TOK_LBRACE);
    while (current_token()->type != TOK_RBRACE) {
        parse_statement();
    }
    expect_token(TOK_RBRACE);
    
    snprintf(instr, sizeof(instr), "JMP %s", end_label);
    emit(instr);
    
    emit_label(else_label);
    
    // Parse else block if present
    if (current_token()->type == TOK_ELSE) {
        advance_token();
        expect_token(TOK_LBRACE);
        while (current_token()->type != TOK_RBRACE) {
            parse_statement();
        }
        expect_token(TOK_RBRACE);
    }
    
    emit_label(end_label);
}

void parse_while_statement() {
    expect_token(TOK_WHILE);
    
    char *loop_label = generate_label("LOOP");
    char *end_label = generate_label("END_LOOP");
    
    emit_label(loop_label);
    
    expect_token(TOK_LPAREN);
    int cond_reg = parse_expression();
    expect_token(TOK_RPAREN);
    
    char instr[256];
    snprintf(instr, sizeof(instr), "CMP R%d, R0", cond_reg);
    emit(instr);
    snprintf(instr, sizeof(instr), "JZ %s", end_label);
    emit(instr);
    
    expect_token(TOK_LBRACE);
    while (current_token()->type != TOK_RBRACE) {
        parse_statement();
    }
    expect_token(TOK_RBRACE);
    
    snprintf(instr, sizeof(instr), "JMP %s", loop_label);
    emit(instr);
    
    emit_label(end_label);
}

void parse_return_statement() {
    expect_token(TOK_RETURN);
    
    if (current_token()->type != TOK_SEMICOLON) {
        int value_reg = parse_expression();
        if (value_reg != 1) {
            char instr[256];
            snprintf(instr, sizeof(instr), "MOVE R1, R%d", value_reg);
            emit(instr);
        }
    }
    
    emit("HALT");  // For main function
    expect_token(TOK_SEMICOLON);
}

void parse_expression_statement() {
    parse_expression();
    expect_token(TOK_SEMICOLON);
}

void parse_statement() {
    Token *tok = current_token();
    
    if (tok->type == TOK_STRUCT) {
        // Check if this is a struct definition or variable declaration
        if (token_stream.pos + 2 < token_stream.count && 
            token_stream.tokens[token_stream.pos + 2].type == TOK_LBRACE) {
            parse_struct_definition();
        } else {
            parse_var_declaration();
        }
    } else if (tok->type == TOK_INT) {
        parse_var_declaration();
    } else if (tok->type == TOK_IF) {
        parse_if_statement();
    } else if (tok->type == TOK_WHILE) {
        parse_while_statement();
    } else if (tok->type == TOK_RETURN) {
        parse_return_statement();
    } else if (tok->type == TOK_IDENTIFIER) {
        // Enhanced lookahead for complex assignment patterns: id.member[index] = value
        int lookahead = 1;
        bool is_assignment = false;
        
        while (token_stream.pos + lookahead < token_stream.count) {
            TokenType ahead_type = token_stream.tokens[token_stream.pos + lookahead].type;
            if (ahead_type == TOK_ASSIGN) {
                is_assignment = true;
                break;
            } else if (ahead_type == TOK_LBRACKET || ahead_type == TOK_DOT || 
                       ahead_type == TOK_RBRACKET || ahead_type == TOK_IDENTIFIER || 
                       ahead_type == TOK_NUMBER) {
                lookahead++;
                continue;
            } else {
                break;
            }
        }
        
        if (is_assignment) {
            parse_assignment();
        } else {
            parse_expression_statement();
        }
    } else if (current_token()->type == TOK_MULTIPLY) {
        parse_assignment();
    } else {
        parser_error("Unexpected token in statement");
    }
}

void parse_function() {
    // Parse return type
    Token *return_type = advance_token();
    if (return_type->type != TOK_INT && return_type->type != TOK_VOID && return_type->type != TOK_STRUCT) {
        parser_error("Expected return type");
    }
    
    // JVM Enhancement: Handle struct return types
    if (return_type->type == TOK_STRUCT) {
        expect_token(TOK_IDENTIFIER);  // struct type name
    }
    
    // Parse function name
    Token *name_tok = expect_token(TOK_IDENTIFIER);
    
    // Generate function label
    char instr[256];
    snprintf(instr, sizeof(instr), "; Function: %s", name_tok->value);
    emit(instr);
    emit_label(name_tok->value);
    
    // Parse parameters
    expect_token(TOK_LPAREN);
    
    // JVM Enhancement: Parse function parameters
    int param_count = 0;
    while (current_token()->type != TOK_RPAREN) {
        if (param_count > 0) {
            expect_token(TOK_COMMA);
        }
        
        // Parse parameter type
        Token *param_type = current_token();
        if (param_type->type == TOK_INT) {
            advance_token();
        } else if (param_type->type == TOK_STRUCT) {
            advance_token();
            expect_token(TOK_IDENTIFIER);  // struct type name
        } else {
            parser_error("Expected parameter type");
        }
        
        // Handle pointer parameters
        bool is_pointer = false;
        if (current_token()->type == TOK_MULTIPLY) {
            is_pointer = true;
            advance_token();
        }
        
        // Parse parameter name
        Token *param_name = expect_token(TOK_IDENTIFIER);
        
        // Allocate register for parameter (parameters passed in R2, R3, etc.)
        int param_reg = allocate_register(param_name->value);
        
        // Emit code to move parameter from calling convention register
        char param_instr[256];
        snprintf(param_instr, sizeof(param_instr), "MOVE R%d, R%d", param_reg, param_count + 2);
        emit(param_instr);
        
        param_count++;
        if (param_count >= 14) {  // R2-R15 available for parameters
            parser_error("Too many parameters");
        }
    }
    expect_token(TOK_RPAREN);
    
    // Parse function body
    expect_token(TOK_LBRACE);
    while (current_token()->type != TOK_RBRACE) {
        parse_statement();
    }
    expect_token(TOK_RBRACE);
    
    // Add function epilogue
    if (strcmp(name_tok->value, "main") == 0) {
        emit("HALT");
    } else {
        emit("RET");
    }
    emit("");
}

void parse_program() {
    while (current_token()->type != TOK_EOF) {
        // JVM Enhancement: Handle struct definitions at top level
        if (current_token()->type == TOK_STRUCT && 
            token_stream.pos + 2 < token_stream.count &&
            token_stream.tokens[token_stream.pos + 2].type == TOK_LBRACE) {
            parse_struct_definition();
        } else {
            parse_function();
        }
    }
}

void generate_code() {
    // Initialize code generator
    codegen.count = 0;
    codegen.var_count = 0;
    codegen.struct_count = 0;     // JVM Enhancement: Initialize struct count
    codegen.next_reg = 1;  // R0 is always zero
    codegen.label_counter = 0;
    codegen.heap_ptr = 0x20000;   // JVM Enhancement: Start heap at 128KB
    
    // Generate startup code
    emit("; Generated by Enhanced C Compiler");
    emit("; Support for arrays, structs, malloc, and JVM features");
    emit(".org 0x8000");
    emit("");
    emit("; Initialize stack pointer");
    emit("LOADI R30, #0x000F0000");
    emit("; Initialize heap pointer");
    emit("LOADI R29, #0x20000");  // 128KB heap start
    emit("");
    
    // Parse the program
    token_stream.pos = 0;
    parse_program();
    
    emit("");
    emit("HALT");
}

// Main function
int main(int argc, char *argv[]) {
    if (argc != 2) {
        fprintf(stderr, "Usage: %s <input.c>\n", argv[0]);
        return 1;
    }
    
    const char *input_file = argv[1];
    char output_file[512];
    strcpy(output_file, input_file);
    
    // Change extension from .c to .asm
    char *dot = strrchr(output_file, '.');
    if (dot && strcmp(dot, ".c") == 0) {
        strcpy(dot, ".asm");
    } else {
        strcat(output_file, ".asm");
    }
    
    // Read input file
    FILE *fp = fopen(input_file, "r");
    if (!fp) {
        fprintf(stderr, "Error: Cannot open file %s\n", input_file);
        return 1;
    }
    
    // Get file size
    fseek(fp, 0, SEEK_END);
    long file_size = ftell(fp);
    fseek(fp, 0, SEEK_SET);
    
    // Read file content
    char *content = malloc(file_size + 1);
    if (!content) {
        fprintf(stderr, "Error: Memory allocation failed\n");
        fclose(fp);
        return 1;
    }
    
    fread(content, 1, file_size, fp);
    content[file_size] = '\0';
    fclose(fp);
    
    // Compile
    tokenize(content);
    generate_code();
    
    // Write output file
    FILE *out_fp = fopen(output_file, "w");
    if (!out_fp) {
        fprintf(stderr, "Error: Cannot create output file %s\n", output_file);
        free(content);
        return 1;
    }
    
    for (int i = 0; i < codegen.count; i++) {
        fprintf(out_fp, "%s\n", codegen.lines[i]);
    }
    
    fclose(out_fp);
    fprintf(stderr, "Compiled %s to %s\n", input_file, output_file);
    
    free(content);
    return 0;
}
