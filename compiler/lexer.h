/*
 * Lexer - Tokenizes C source code
 */

#ifndef LEXER_H
#define LEXER_H

// Token types
typedef enum {
    // Literals
    TOK_INT_LITERAL,
    TOK_FLOAT_LITERAL,
    TOK_CHAR_LITERAL,
    TOK_STRING_LITERAL,
    
    // Identifiers and keywords
    TOK_IDENTIFIER,
    TOK_INT, TOK_CHAR, TOK_FLOAT, TOK_DOUBLE, TOK_VOID,
    TOK_IF, TOK_ELSE, TOK_WHILE, TOK_FOR, TOK_RETURN,
    TOK_BREAK, TOK_CONTINUE,
    TOK_STRUCT, TOK_ENUM, TOK_TYPEDEF,
    
    // Operators
    TOK_PLUS, TOK_MINUS, TOK_MULTIPLY, TOK_DIVIDE, TOK_MODULO,
    TOK_ASSIGN, TOK_PLUS_ASSIGN, TOK_MINUS_ASSIGN, TOK_MUL_ASSIGN, TOK_DIV_ASSIGN,
    TOK_EQ, TOK_NE, TOK_LT, TOK_LE, TOK_GT, TOK_GE,
    TOK_AND, TOK_OR, TOK_NOT,
    TOK_BITAND, TOK_BITOR, TOK_BITXOR, TOK_BITNOT, TOK_SHL, TOK_SHR,
    TOK_INCREMENT, TOK_DECREMENT,
    TOK_DOT, TOK_ARROW,
    
    // Delimiters
    TOK_SEMICOLON, TOK_COMMA,
    TOK_LPAREN, TOK_RPAREN,
    TOK_LBRACE, TOK_RBRACE,
    TOK_LBRACKET, TOK_RBRACKET,
    
    // Special
    TOK_EOF,
    TOK_ERROR
} TokenType;

// Token structure
typedef struct {
    TokenType type;
    char* value;
    int line;
    int column;
} Token;

// Token list
typedef struct {
    Token* tokens;
    int count;
    int capacity;
    int current;  // For parsing
} TokenList;

// Function prototypes
TokenList* tokenize(const char* source);
void free_tokens(TokenList* tokens);
void print_tokens(TokenList* tokens);
const char* token_type_name(TokenType type);

#endif
