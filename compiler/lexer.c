/*
 * Lexer Implementation
 */

#include "lexer.h"
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <stdio.h>

#define INITIAL_CAPACITY 256

static const char* keywords[] = {
    "int", "char", "float", "double", "void",
    "if", "else", "while", "for", "return",
    "break", "continue", "struct", "enum", "typedef"
};

static const TokenType keyword_tokens[] = {
    TOK_INT, TOK_CHAR, TOK_FLOAT, TOK_DOUBLE, TOK_VOID,
    TOK_IF, TOK_ELSE, TOK_WHILE, TOK_FOR, TOK_RETURN,
    TOK_BREAK, TOK_CONTINUE, TOK_STRUCT, TOK_ENUM, TOK_TYPEDEF
};

#define NUM_KEYWORDS (sizeof(keywords) / sizeof(keywords[0]))

typedef struct {
    const char* source;
    int pos;
    int line;
    int column;
} Lexer;

static char peek(Lexer* lexer, int offset) {
    int pos = lexer->pos + offset;
    if (lexer->source[pos] == '\0') return '\0';
    return lexer->source[pos];
}

static char advance(Lexer* lexer) {
    char ch = lexer->source[lexer->pos];
    if (ch == '\0') return '\0';
    
    lexer->pos++;
    if (ch == '\n') {
        lexer->line++;
        lexer->column = 1;
    } else {
        lexer->column++;
    }
    return ch;
}

static void skip_whitespace(Lexer* lexer) {
    while (isspace(peek(lexer, 0))) {
        advance(lexer);
    }
}

static void skip_preprocessor(Lexer* lexer) {
    // Skip preprocessor directives (lines starting with #)
    if (peek(lexer, 0) == '#') {
        // Skip the entire line until newline or end of file
        while (peek(lexer, 0) != '\n' && peek(lexer, 0) != '\0') {
            advance(lexer);
        }
        // Skip the newline character if present
        if (peek(lexer, 0) == '\n') {
            advance(lexer);
        }
    }
}

static void skip_comment(Lexer* lexer) {
    if (peek(lexer, 0) == '/' && peek(lexer, 1) == '/') {
        // Single-line comment
        while (peek(lexer, 0) != '\n' && peek(lexer, 0) != '\0') {
            advance(lexer);
        }
    } else if (peek(lexer, 0) == '/' && peek(lexer, 1) == '*') {
        // Multi-line comment
        advance(lexer); // '/'
        advance(lexer); // '*'
        while (!(peek(lexer, 0) == '*' && peek(lexer, 1) == '/') && peek(lexer, 0) != '\0') {
            advance(lexer);
        }
        if (peek(lexer, 0) != '\0') {
            advance(lexer); // '*'
            advance(lexer); // '/'
        }
    }
}

static Token make_token(TokenType type, const char* value, int line, int column) {
    Token token;
    token.type = type;
    token.value = strdup(value);
    token.line = line;
    token.column = column;
    return token;
}

static Token read_number(Lexer* lexer) {
    int start_line = lexer->line;
    int start_column = lexer->column;
    char buffer[256];
    int i = 0;
    int has_dot = 0;
    
    while (isdigit(peek(lexer, 0)) || peek(lexer, 0) == '.') {
        char ch = peek(lexer, 0);
        if (ch == '.') {
            if (has_dot) break; // Second dot, stop
            has_dot = 1;
        }
        buffer[i++] = advance(lexer);
        if (i >= sizeof(buffer) - 1) break;
    }
    
    buffer[i] = '\0';
    return make_token(has_dot ? TOK_FLOAT_LITERAL : TOK_INT_LITERAL, 
                     buffer, start_line, start_column);
}

static Token read_string(Lexer* lexer) {
    int start_line = lexer->line;
    int start_column = lexer->column;
    char buffer[1024];
    int i = 0;
    
    advance(lexer); // Skip opening quote
    
    while (peek(lexer, 0) != '"' && peek(lexer, 0) != '\0') {
        char ch = peek(lexer, 0);
        if (ch == '\\') {
            advance(lexer); // Skip backslash
            ch = peek(lexer, 0);
            switch (ch) {
                case 'n': buffer[i++] = '\n'; break;
                case 't': buffer[i++] = '\t'; break;
                case 'r': buffer[i++] = '\r'; break;
                case '\\': buffer[i++] = '\\'; break;
                case '"': buffer[i++] = '"'; break;
                default: buffer[i++] = ch; break;
            }
            advance(lexer);
        } else {
            buffer[i++] = advance(lexer);
        }
        if (i >= sizeof(buffer) - 1) break;
    }
    
    if (peek(lexer, 0) == '"') {
        advance(lexer); // Skip closing quote
    }
    
    buffer[i] = '\0';
    return make_token(TOK_STRING_LITERAL, buffer, start_line, start_column);
}

static Token read_char(Lexer* lexer) {
    int start_line = lexer->line;
    int start_column = lexer->column;
    char buffer[4];
    
    advance(lexer); // Skip opening quote
    
    if (peek(lexer, 0) == '\\') {
        advance(lexer);
        char ch = advance(lexer);
        switch (ch) {
            case 'n': buffer[0] = '\n'; break;
            case 't': buffer[0] = '\t'; break;
            case 'r': buffer[0] = '\r'; break;
            case '\\': buffer[0] = '\\'; break;
            case '\'': buffer[0] = '\''; break;
            default: buffer[0] = ch; break;
        }
    } else {
        buffer[0] = advance(lexer);
    }
    
    if (peek(lexer, 0) == '\'') {
        advance(lexer); // Skip closing quote
    }
    
    buffer[1] = '\0';
    return make_token(TOK_CHAR_LITERAL, buffer, start_line, start_column);
}

static Token read_identifier(Lexer* lexer) {
    int start_line = lexer->line;
    int start_column = lexer->column;
    char buffer[256];
    int i = 0;
    
    while (isalnum(peek(lexer, 0)) || peek(lexer, 0) == '_') {
        buffer[i++] = advance(lexer);
        if (i >= sizeof(buffer) - 1) break;
    }
    
    buffer[i] = '\0';
    
    // Check if it's a keyword
    for (int j = 0; j < NUM_KEYWORDS; j++) {
        if (strcmp(buffer, keywords[j]) == 0) {
            return make_token(keyword_tokens[j], buffer, start_line, start_column);
        }
    }
    
    return make_token(TOK_IDENTIFIER, buffer, start_line, start_column);
}

static void add_token(TokenList* list, Token token) {
    if (list->count >= list->capacity) {
        list->capacity *= 2;
        list->tokens = realloc(list->tokens, list->capacity * sizeof(Token));
    }
    list->tokens[list->count++] = token;
}

TokenList* tokenize(const char* source) {
    TokenList* list = malloc(sizeof(TokenList));
    list->tokens = malloc(INITIAL_CAPACITY * sizeof(Token));
    list->count = 0;
    list->capacity = INITIAL_CAPACITY;
    list->current = 0;
    
    Lexer lexer = {source, 0, 1, 1};
    
    while (peek(&lexer, 0) != '\0') {
        skip_whitespace(&lexer);
        
        if (peek(&lexer, 0) == '\0') break;
        
        // Skip comments
        if (peek(&lexer, 0) == '/' && (peek(&lexer, 1) == '/' || peek(&lexer, 1) == '*')) {
            skip_comment(&lexer);
            continue;
        }
        
        // Skip preprocessor directives
        if (peek(&lexer, 0) == '#') {
            skip_preprocessor(&lexer);
            continue;
        }
        
        char ch = peek(&lexer, 0);
        int line = lexer.line;
        int column = lexer.column;
        
        if (isdigit(ch)) {
            add_token(list, read_number(&lexer));
        } else if (ch == '"') {
            add_token(list, read_string(&lexer));
        } else if (ch == '\'') {
            add_token(list, read_char(&lexer));
        } else if (isalpha(ch) || ch == '_') {
            add_token(list, read_identifier(&lexer));
        } else {
            // Single and multi-character operators
            advance(&lexer);
            switch (ch) {
                case '+':
                    if (peek(&lexer, 0) == '+') {
                        advance(&lexer);
                        add_token(list, make_token(TOK_INCREMENT, "++", line, column));
                    } else if (peek(&lexer, 0) == '=') {
                        advance(&lexer);
                        add_token(list, make_token(TOK_PLUS_ASSIGN, "+=", line, column));
                    } else {
                        add_token(list, make_token(TOK_PLUS, "+", line, column));
                    }
                    break;
                case '-':
                    if (peek(&lexer, 0) == '-') {
                        advance(&lexer);
                        add_token(list, make_token(TOK_DECREMENT, "--", line, column));
                    } else if (peek(&lexer, 0) == '=') {
                        advance(&lexer);
                        add_token(list, make_token(TOK_MINUS_ASSIGN, "-=", line, column));
                    } else if (peek(&lexer, 0) == '>') {
                        advance(&lexer);
                        add_token(list, make_token(TOK_ARROW, "->", line, column));
                    } else {
                        add_token(list, make_token(TOK_MINUS, "-", line, column));
                    }
                    break;
                case '*':
                    if (peek(&lexer, 0) == '=') {
                        advance(&lexer);
                        add_token(list, make_token(TOK_MUL_ASSIGN, "*=", line, column));
                    } else {
                        add_token(list, make_token(TOK_MULTIPLY, "*", line, column));
                    }
                    break;
                case '/':
                    if (peek(&lexer, 0) == '=') {
                        advance(&lexer);
                        add_token(list, make_token(TOK_DIV_ASSIGN, "/=", line, column));
                    } else {
                        add_token(list, make_token(TOK_DIVIDE, "/", line, column));
                    }
                    break;
                case '%':
                    add_token(list, make_token(TOK_MODULO, "%", line, column));
                    break;
                case '=':
                    if (peek(&lexer, 0) == '=') {
                        advance(&lexer);
                        add_token(list, make_token(TOK_EQ, "==", line, column));
                    } else {
                        add_token(list, make_token(TOK_ASSIGN, "=", line, column));
                    }
                    break;
                case '!':
                    if (peek(&lexer, 0) == '=') {
                        advance(&lexer);
                        add_token(list, make_token(TOK_NE, "!=", line, column));
                    } else {
                        add_token(list, make_token(TOK_NOT, "!", line, column));
                    }
                    break;
                case '<':
                    if (peek(&lexer, 0) == '=') {
                        advance(&lexer);
                        add_token(list, make_token(TOK_LE, "<=", line, column));
                    } else if (peek(&lexer, 0) == '<') {
                        advance(&lexer);
                        add_token(list, make_token(TOK_SHL, "<<", line, column));
                    } else {
                        add_token(list, make_token(TOK_LT, "<", line, column));
                    }
                    break;
                case '>':
                    if (peek(&lexer, 0) == '=') {
                        advance(&lexer);
                        add_token(list, make_token(TOK_GE, ">=", line, column));
                    } else if (peek(&lexer, 0) == '>') {
                        advance(&lexer);
                        add_token(list, make_token(TOK_SHR, ">>", line, column));
                    } else {
                        add_token(list, make_token(TOK_GT, ">", line, column));
                    }
                    break;
                case '&':
                    if (peek(&lexer, 0) == '&') {
                        advance(&lexer);
                        add_token(list, make_token(TOK_AND, "&&", line, column));
                    } else {
                        add_token(list, make_token(TOK_BITAND, "&", line, column));
                    }
                    break;
                case '|':
                    if (peek(&lexer, 0) == '|') {
                        advance(&lexer);
                        add_token(list, make_token(TOK_OR, "||", line, column));
                    } else {
                        add_token(list, make_token(TOK_BITOR, "|", line, column));
                    }
                    break;
                case '^':
                    add_token(list, make_token(TOK_BITXOR, "^", line, column));
                    break;
                case '~':
                    add_token(list, make_token(TOK_BITNOT, "~", line, column));
                    break;
                case '.':
                    add_token(list, make_token(TOK_DOT, ".", line, column));
                    break;
                case ';':
                    add_token(list, make_token(TOK_SEMICOLON, ";", line, column));
                    break;
                case ',':
                    add_token(list, make_token(TOK_COMMA, ",", line, column));
                    break;
                case '(':
                    add_token(list, make_token(TOK_LPAREN, "(", line, column));
                    break;
                case ')':
                    add_token(list, make_token(TOK_RPAREN, ")", line, column));
                    break;
                case '{':
                    add_token(list, make_token(TOK_LBRACE, "{", line, column));
                    break;
                case '}':
                    add_token(list, make_token(TOK_RBRACE, "}", line, column));
                    break;
                case '[':
                    add_token(list, make_token(TOK_LBRACKET, "[", line, column));
                    break;
                case ']':
                    add_token(list, make_token(TOK_RBRACKET, "]", line, column));
                    break;
                case '?':
                    add_token(list, make_token(TOK_QUESTION, "?", line, column));
                    break;
                case ':':
                    add_token(list, make_token(TOK_COLON, ":", line, column));
                    break;
                default: {
                    // Unknown character - create error token
                    char error_msg[32];
                    snprintf(error_msg, sizeof(error_msg), "Unexpected character: %c", ch);
                    add_token(list, make_token(TOK_ERROR, error_msg, line, column));
                    break;
                }
            }
        }
    }
    
    // Add EOF token
    add_token(list, make_token(TOK_EOF, "", lexer.line, lexer.column));
    
    return list;
}

void free_tokens(TokenList* tokens) {
    if (!tokens) return;
    
    for (int i = 0; i < tokens->count; i++) {
        free(tokens->tokens[i].value);
    }
    free(tokens->tokens);
    free(tokens);
}

const char* token_type_name(TokenType type) {
    switch (type) {
        case TOK_INT_LITERAL: return "INT_LITERAL";
        case TOK_FLOAT_LITERAL: return "FLOAT_LITERAL";
        case TOK_CHAR_LITERAL: return "CHAR_LITERAL";
        case TOK_STRING_LITERAL: return "STRING_LITERAL";
        case TOK_IDENTIFIER: return "IDENTIFIER";
        case TOK_INT: return "INT";
        case TOK_CHAR: return "CHAR";
        case TOK_FLOAT: return "FLOAT";
        case TOK_DOUBLE: return "DOUBLE";
        case TOK_VOID: return "VOID";
        case TOK_IF: return "IF";
        case TOK_ELSE: return "ELSE";
        case TOK_WHILE: return "WHILE";
        case TOK_FOR: return "FOR";
        case TOK_RETURN: return "RETURN";
        case TOK_BREAK: return "BREAK";
        case TOK_CONTINUE: return "CONTINUE";
        case TOK_STRUCT: return "STRUCT";
        case TOK_ENUM: return "ENUM";
        case TOK_TYPEDEF: return "TYPEDEF";
        case TOK_PLUS: return "PLUS";
        case TOK_MINUS: return "MINUS";
        case TOK_MULTIPLY: return "MULTIPLY";
        case TOK_DIVIDE: return "DIVIDE";
        case TOK_MODULO: return "MODULO";
        case TOK_ASSIGN: return "ASSIGN";
        case TOK_EQ: return "EQ";
        case TOK_NE: return "NE";
        case TOK_LT: return "LT";
        case TOK_LE: return "LE";
        case TOK_GT: return "GT";
        case TOK_GE: return "GE";
        case TOK_AND: return "AND";
        case TOK_OR: return "OR";
        case TOK_NOT: return "NOT";
        case TOK_DOT: return "DOT";
        case TOK_ARROW: return "ARROW";
        case TOK_SEMICOLON: return "SEMICOLON";
        case TOK_COMMA: return "COMMA";
        case TOK_LPAREN: return "LPAREN";
        case TOK_RPAREN: return "RPAREN";
        case TOK_LBRACE: return "LBRACE";
        case TOK_RBRACE: return "RBRACE";
        case TOK_LBRACKET: return "LBRACKET";
        case TOK_RBRACKET: return "RBRACKET";
        case TOK_QUESTION: return "QUESTION";
        case TOK_COLON: return "COLON";
        case TOK_EOF: return "EOF";
        case TOK_ERROR: return "ERROR";
        default: return "UNKNOWN";
    }
}

void print_tokens(TokenList* tokens) {
    for (int i = 0; i < tokens->count; i++) {
        Token* tok = &tokens->tokens[i];
        printf("%3d: %-15s '%s' at %d:%d\n", 
               i, token_type_name(tok->type), tok->value, tok->line, tok->column);
    }
}
