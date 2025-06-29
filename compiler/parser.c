/*
 * Parser Implementation
 * Recursive descent parser for C language subset
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "parser.h"
#include "ast.h"

// Error reporting
void parser_error(Parser* parser, const char* message) {
    Token* token = peek(parser);
    printf("Parse error at line %d, column %d: %s\n", 
           token->line, token->column, message);
    printf("Near token: %s\n", token->value ? token->value : token_type_name(token->type));
    parser->had_error = 1;
}

// Token manipulation helpers
int match(Parser* parser, TokenType type) {
    if (check(parser, type)) {
        advance(parser);
        return 1;
    }
    return 0;
}

int check(Parser* parser, TokenType type) {
    if (is_at_end(parser)) return 0;
    return peek(parser)->type == type;
}

Token* advance(Parser* parser) {
    if (!is_at_end(parser)) parser->current++;
    return previous(parser);
}

Token* peek(Parser* parser) {
    return &parser->tokens->tokens[parser->current];
}

Token* previous(Parser* parser) {
    return &parser->tokens->tokens[parser->current - 1];
}

int is_at_end(Parser* parser) {
    return peek(parser)->type == TOK_EOF;
}

// Main parse function
AstNode* parse(TokenList* tokens) {
    Parser parser = {
        .tokens = tokens,
        .current = 0,
        .had_error = 0
    };
    
    AstNode* program = parse_program(&parser);
    
    if (parser.had_error) {
        if (program) free_ast(program);
        return NULL;
    }
    
    return program;
}

// Parse program (list of declarations)
AstNode* parse_program(Parser* parser) {
    AstNode* program = create_compound_stmt();
    
    while (!is_at_end(parser)) {
        AstNode* decl = parse_declaration(parser);
        if (decl) {
            add_child(program, decl);
        } else if (parser->had_error) {
            // Synchronize after error
            while (!is_at_end(parser) && !check(parser, TOK_SEMICOLON) && 
                   !check(parser, TOK_LBRACE) && !check(parser, TOK_RBRACE)) {
                advance(parser);
            }
            if (check(parser, TOK_SEMICOLON)) advance(parser);
            parser->had_error = 0; // Reset error state
        }
    }
    
    return program;
}

// Parse declaration
AstNode* parse_declaration(Parser* parser) {
    // Check for type keywords to distinguish declarations from expressions
    if (check(parser, TOK_INT) || check(parser, TOK_CHAR) || check(parser, TOK_FLOAT) || 
        check(parser, TOK_DOUBLE) || check(parser, TOK_VOID)) {
        
        // Try to parse as function or variable declaration
        int saved_pos = parser->current;
        Type* type = parse_type(parser);
        if (!type) {
            parser->current = saved_pos;
            parser_error(parser, "Expected type specifier");
            return NULL;
        }
        
        if (!check(parser, TOK_IDENTIFIER)) {
            parser_error(parser, "Expected identifier");
            free_type(type);
            return NULL;
        }
        
        char* name = strdup(peek(parser)->value);
        advance(parser);
        
        if (check(parser, TOK_LPAREN)) {
            // Function declaration
            parser->current = saved_pos;
            free(name);
            free_type(type);
            return parse_function_declaration(parser);
        } else {
            // Variable declaration
            parser->current = saved_pos;
            free(name);
            free_type(type);
            return parse_variable_declaration(parser);
        }
    }
    
    if (check(parser, TOK_STRUCT)) {
        return parse_struct_declaration(parser);
    }
    if (check(parser, TOK_ENUM)) {
        return parse_enum_declaration(parser);
    }
    if (check(parser, TOK_TYPEDEF)) {
        return parse_typedef_declaration(parser);
    }
    
    // If not a declaration, try to parse as statement (for top-level expressions)
    return parse_statement(parser);
}

// Parse function declaration
AstNode* parse_function_declaration(Parser* parser) {
    Type* return_type = parse_type(parser);
    if (!return_type) {
        parser_error(parser, "Expected return type");
        return NULL;
    }
    
    if (!check(parser, TOK_IDENTIFIER)) {
        parser_error(parser, "Expected function name");
        free_type(return_type);
        return NULL;
    }
    
    char* name = strdup(peek(parser)->value);
    advance(parser);
    
    if (!match(parser, TOK_LPAREN)) {
        parser_error(parser, "Expected '(' after function name");
        free(name);
        free_type(return_type);
        return NULL;
    }
    
    AstNode* params = parse_parameter_list(parser);
    
    if (!match(parser, TOK_RPAREN)) {
        parser_error(parser, "Expected ')' after parameters");
        free(name);
        free_type(return_type);
        if (params) free_ast(params);
        return NULL;
    }
    
    AstNode* body = NULL;
    if (check(parser, TOK_LBRACE)) {
        body = parse_compound_statement(parser);
        if (!body) {
            free(name);
            free_type(return_type);
            if (params) free_ast(params);
            return NULL;
        }
    } else if (!match(parser, TOK_SEMICOLON)) {
        parser_error(parser, "Expected '{' or ';' after function declaration");
        free(name);
        free_type(return_type);
        if (params) free_ast(params);
        return NULL;
    }
    
    AstNode* func = create_function_decl(name, return_type, params, body);
    free(name);
    return func;
}

// Parse variable declaration
AstNode* parse_variable_declaration(Parser* parser) {
    Type* type = parse_type(parser);
    if (!type) {
        parser_error(parser, "Expected type specifier");
        return NULL;
    }
    
    if (!check(parser, TOK_IDENTIFIER)) {
        parser_error(parser, "Expected variable name");
        free_type(type);
        return NULL;
    }
    
    char* name = strdup(peek(parser)->value);
    advance(parser);
    
    AstNode* initializer = NULL;
    if (match(parser, TOK_ASSIGN)) {
        initializer = parse_expression(parser);
        if (!initializer) {
            free(name);
            free_type(type);
            return NULL;
        }
    }
    
    if (!match(parser, TOK_SEMICOLON)) {
        parser_error(parser, "Expected ';' after variable declaration");
        free(name);
        free_type(type);
        if (initializer) free_ast(initializer);
        return NULL;
    }
    
    AstNode* var_decl = create_variable_decl(name, type, initializer);
    free(name);
    return var_decl;
}

// Parse struct declaration (placeholder)
AstNode* parse_struct_declaration(Parser* parser) {
    advance(parser); // consume 'struct'
    
    if (!check(parser, TOK_IDENTIFIER)) {
        parser_error(parser, "Expected struct name");
        return NULL;
    }
    
    char* name = strdup(peek(parser)->value);
    advance(parser);
    
    if (!match(parser, TOK_LBRACE)) {
        parser_error(parser, "Expected '{' after struct name");
        free(name);
        return NULL;
    }
    
    // Skip struct body for now
    int brace_count = 1;
    while (brace_count > 0 && !is_at_end(parser)) {
        if (peek(parser)->type == TOK_LBRACE) brace_count++;
        if (peek(parser)->type == TOK_RBRACE) brace_count--;
        advance(parser);
    }
    
    if (!match(parser, TOK_SEMICOLON)) {
        parser_error(parser, "Expected ';' after struct declaration");
        free(name);
        return NULL;
    }
    
    // Create placeholder struct declaration
    AstNode* struct_decl = create_struct_decl(name, NULL);
    free(name);
    return struct_decl;
}

// Parse enum declaration (placeholder)
AstNode* parse_enum_declaration(Parser* parser) {
    advance(parser); // consume 'enum'
    
    if (!check(parser, TOK_IDENTIFIER)) {
        parser_error(parser, "Expected enum name");
        return NULL;
    }
    
    char* name = strdup(peek(parser)->value);
    advance(parser);
    
    if (!match(parser, TOK_LBRACE)) {
        parser_error(parser, "Expected '{' after enum name");
        free(name);
        return NULL;
    }
    
    // Skip enum body for now
    int brace_count = 1;
    while (brace_count > 0 && !is_at_end(parser)) {
        if (peek(parser)->type == TOK_LBRACE) brace_count++;
        if (peek(parser)->type == TOK_RBRACE) brace_count--;
        advance(parser);
    }
    
    if (!match(parser, TOK_SEMICOLON)) {
        parser_error(parser, "Expected ';' after enum declaration");
        free(name);
        return NULL;
    }
    
    // Create placeholder enum declaration
    AstNode* enum_decl = create_enum_decl(name, NULL);
    free(name);
    return enum_decl;
}

// Parse typedef declaration (placeholder)
AstNode* parse_typedef_declaration(Parser* parser) {
    advance(parser); // consume 'typedef'
    
    Type* type = parse_type(parser);
    if (!type) {
        parser_error(parser, "Expected type in typedef");
        return NULL;
    }
    
    if (!check(parser, TOK_IDENTIFIER)) {
        parser_error(parser, "Expected identifier in typedef");
        free_type(type);
        return NULL;
    }
    
    char* name = strdup(peek(parser)->value);
    advance(parser);
    
    if (!match(parser, TOK_SEMICOLON)) {
        parser_error(parser, "Expected ';' after typedef");
        free(name);
        free_type(type);
        return NULL;
    }
    
    AstNode* typedef_decl = create_typedef_decl(name, type);
    free(name);
    return typedef_decl;
}

// Parse statement
AstNode* parse_statement(Parser* parser) {
    // Check for declarations first (for local variables)
    if (check(parser, TOK_INT) || check(parser, TOK_CHAR) || check(parser, TOK_FLOAT) || 
        check(parser, TOK_DOUBLE) || check(parser, TOK_VOID)) {
        return parse_variable_declaration(parser);
    }
    
    if (check(parser, TOK_LBRACE)) {
        return parse_compound_statement(parser);
    }
    if (check(parser, TOK_IF)) {
        return parse_if_statement(parser);
    }
    if (check(parser, TOK_WHILE)) {
        return parse_while_statement(parser);
    }
    if (check(parser, TOK_FOR)) {
        return parse_for_statement(parser);
    }
    if (check(parser, TOK_RETURN)) {
        return parse_return_statement(parser);
    }
    if (check(parser, TOK_BREAK)) {
        return parse_break_statement(parser);
    }
    if (check(parser, TOK_CONTINUE)) {
        return parse_continue_statement(parser);
    }
    
    return parse_expression_statement(parser);
}

// Parse compound statement
AstNode* parse_compound_statement(Parser* parser) {
    if (!match(parser, TOK_LBRACE)) {
        parser_error(parser, "Expected '{'");
        return NULL;
    }
    
    AstNode* compound = create_compound_stmt();
    
    while (!check(parser, TOK_RBRACE) && !is_at_end(parser)) {
        AstNode* stmt = parse_statement(parser);
        if (stmt) {
            add_child(compound, stmt);
        } else if (parser->had_error) {
            // Error recovery
            while (!is_at_end(parser) && !check(parser, TOK_SEMICOLON) && 
                   !check(parser, TOK_RBRACE)) {
                advance(parser);
            }
            if (check(parser, TOK_SEMICOLON)) advance(parser);
            parser->had_error = 0;
        }
    }
    
    if (!match(parser, TOK_RBRACE)) {
        parser_error(parser, "Expected '}'");
        free_ast(compound);
        return NULL;
    }
    
    return compound;
}

// Parse if statement
AstNode* parse_if_statement(Parser* parser) {
    advance(parser); // consume 'if'
    
    if (!match(parser, TOK_LPAREN)) {
        parser_error(parser, "Expected '(' after 'if'");
        return NULL;
    }
    
    AstNode* condition = parse_expression(parser);
    if (!condition) return NULL;
    
    if (!match(parser, TOK_RPAREN)) {
        parser_error(parser, "Expected ')' after if condition");
        free_ast(condition);
        return NULL;
    }
    
    AstNode* then_stmt = parse_statement(parser);
    if (!then_stmt) {
        free_ast(condition);
        return NULL;
    }
    
    AstNode* else_stmt = NULL;
    if (match(parser, TOK_ELSE)) {
        else_stmt = parse_statement(parser);
        if (!else_stmt) {
            free_ast(condition);
            free_ast(then_stmt);
            return NULL;
        }
    }
    
    return create_if_stmt(condition, then_stmt, else_stmt);
}

// Parse while statement
AstNode* parse_while_statement(Parser* parser) {
    advance(parser); // consume 'while'
    
    if (!match(parser, TOK_LPAREN)) {
        parser_error(parser, "Expected '(' after 'while'");
        return NULL;
    }
    
    AstNode* condition = parse_expression(parser);
    if (!condition) return NULL;
    
    if (!match(parser, TOK_RPAREN)) {
        parser_error(parser, "Expected ')' after while condition");
        free_ast(condition);
        return NULL;
    }
    
    AstNode* body = parse_statement(parser);
    if (!body) {
        free_ast(condition);
        return NULL;
    }
    
    return create_while_stmt(condition, body);
}

// Parse for statement (simplified)
AstNode* parse_for_statement(Parser* parser) {
    advance(parser); // consume 'for'
    
    if (!match(parser, TOK_LPAREN)) {
        parser_error(parser, "Expected '(' after 'for'");
        return NULL;
    }
    
    // For now, just skip the for statement parts and parse the body
    while (!check(parser, TOK_RPAREN) && !is_at_end(parser)) {
        advance(parser);
    }
    
    if (!match(parser, TOK_RPAREN)) {
        parser_error(parser, "Expected ')' after for clauses");
        return NULL;
    }
    
    AstNode* body = parse_statement(parser);
    if (!body) return NULL;
    
    // Create placeholder for statement - in real implementation would parse init, condition, increment
    return create_for_stmt(NULL, NULL, NULL, body);
}

// Parse return statement
AstNode* parse_return_statement(Parser* parser) {
    advance(parser); // consume 'return'
    
    AstNode* value = NULL;
    if (!check(parser, TOK_SEMICOLON)) {
        value = parse_expression(parser);
        if (!value) return NULL;
    }
    
    if (!match(parser, TOK_SEMICOLON)) {
        parser_error(parser, "Expected ';' after return statement");
        if (value) free_ast(value);
        return NULL;
    }
    
    return create_return_stmt(value);
}

// Parse break statement
AstNode* parse_break_statement(Parser* parser) {
    advance(parser); // consume 'break'
    
    if (!match(parser, TOK_SEMICOLON)) {
        parser_error(parser, "Expected ';' after 'break'");
        return NULL;
    }
    
    return create_break_stmt();
}

// Parse continue statement
AstNode* parse_continue_statement(Parser* parser) {
    advance(parser); // consume 'continue'
    
    if (!match(parser, TOK_SEMICOLON)) {
        parser_error(parser, "Expected ';' after 'continue'");
        return NULL;
    }
    
    return create_continue_stmt();
}

// Parse expression statement
AstNode* parse_expression_statement(Parser* parser) {
    AstNode* expr = parse_expression(parser);
    if (!expr) return NULL;
    
    if (!match(parser, TOK_SEMICOLON)) {
        parser_error(parser, "Expected ';' after expression");
        free_ast(expr);
        return NULL;
    }
    
    return create_expression_stmt(expr);
}

// Parse expression (assignment level)
AstNode* parse_expression(Parser* parser) {
    return parse_assignment(parser);
}

// Parse assignment
AstNode* parse_assignment(Parser* parser) {
    AstNode* expr = parse_logical_or(parser);
    if (!expr) return NULL;
    
    if (match(parser, TOK_ASSIGN) || match(parser, TOK_PLUS_ASSIGN) || 
        match(parser, TOK_MINUS_ASSIGN) || match(parser, TOK_MUL_ASSIGN) || 
        match(parser, TOK_DIV_ASSIGN)) {
        
        TokenType op = previous(parser)->type;
        AstNode* right = parse_assignment(parser);
        if (!right) {
            free_ast(expr);
            return NULL;
        }
        
        return create_assignment(expr, right, op);
    }
    
    return expr;
}

// Parse logical OR
AstNode* parse_logical_or(Parser* parser) {
    AstNode* expr = parse_logical_and(parser);
    if (!expr) return NULL;
    
    while (match(parser, TOK_OR)) {
        TokenType op = previous(parser)->type;
        AstNode* right = parse_logical_and(parser);
        if (!right) {
            free_ast(expr);
            return NULL;
        }
        expr = create_binary_op(expr, right, op);
    }
    
    return expr;
}

// Parse logical AND
AstNode* parse_logical_and(Parser* parser) {
    AstNode* expr = parse_bitwise_or(parser);
    if (!expr) return NULL;
    
    while (match(parser, TOK_AND)) {
        TokenType op = previous(parser)->type;
        AstNode* right = parse_bitwise_or(parser);
        if (!right) {
            free_ast(expr);
            return NULL;
        }
        expr = create_binary_op(expr, right, op);
    }
    
    return expr;
}

// Parse bitwise OR
AstNode* parse_bitwise_or(Parser* parser) {
    AstNode* expr = parse_bitwise_xor(parser);
    if (!expr) return NULL;
    
    while (match(parser, TOK_BITOR)) {
        TokenType op = previous(parser)->type;
        AstNode* right = parse_bitwise_xor(parser);
        if (!right) {
            free_ast(expr);
            return NULL;
        }
        expr = create_binary_op(expr, right, op);
    }
    
    return expr;
}

// Parse bitwise XOR
AstNode* parse_bitwise_xor(Parser* parser) {
    AstNode* expr = parse_bitwise_and(parser);
    if (!expr) return NULL;
    
    while (match(parser, TOK_BITXOR)) {
        TokenType op = previous(parser)->type;
        AstNode* right = parse_bitwise_and(parser);
        if (!right) {
            free_ast(expr);
            return NULL;
        }
        expr = create_binary_op(expr, right, op);
    }
    
    return expr;
}

// Parse bitwise AND
AstNode* parse_bitwise_and(Parser* parser) {
    AstNode* expr = parse_equality(parser);
    if (!expr) return NULL;
    
    while (match(parser, TOK_BITAND)) {
        TokenType op = previous(parser)->type;
        AstNode* right = parse_equality(parser);
        if (!right) {
            free_ast(expr);
            return NULL;
        }
        expr = create_binary_op(expr, right, op);
    }
    
    return expr;
}

// Parse equality
AstNode* parse_equality(Parser* parser) {
    AstNode* expr = parse_comparison(parser);
    if (!expr) return NULL;
    
    while (match(parser, TOK_EQ) || match(parser, TOK_NE)) {
        TokenType op = previous(parser)->type;
        AstNode* right = parse_comparison(parser);
        if (!right) {
            free_ast(expr);
            return NULL;
        }
        expr = create_binary_op(expr, right, op);
    }
    
    return expr;
}

// Parse comparison
AstNode* parse_comparison(Parser* parser) {
    AstNode* expr = parse_shift(parser);
    if (!expr) return NULL;
    
    while (match(parser, TOK_GT) || match(parser, TOK_GE) || 
           match(parser, TOK_LT) || match(parser, TOK_LE)) {
        TokenType op = previous(parser)->type;
        AstNode* right = parse_shift(parser);
        if (!right) {
            free_ast(expr);
            return NULL;
        }
        expr = create_binary_op(expr, right, op);
    }
    
    return expr;
}

// Parse shift
AstNode* parse_shift(Parser* parser) {
    AstNode* expr = parse_term(parser);
    if (!expr) return NULL;
    
    while (match(parser, TOK_SHL) || match(parser, TOK_SHR)) {
        TokenType op = previous(parser)->type;
        AstNode* right = parse_term(parser);
        if (!right) {
            free_ast(expr);
            return NULL;
        }
        expr = create_binary_op(expr, right, op);
    }
    
    return expr;
}

// Parse term (+ -)
AstNode* parse_term(Parser* parser) {
    AstNode* expr = parse_factor(parser);
    if (!expr) return NULL;
    
    while (match(parser, TOK_PLUS) || match(parser, TOK_MINUS)) {
        TokenType op = previous(parser)->type;
        AstNode* right = parse_factor(parser);
        if (!right) {
            free_ast(expr);
            return NULL;
        }
        expr = create_binary_op(expr, right, op);
    }
    
    return expr;
}

// Parse factor (* / %)
AstNode* parse_factor(Parser* parser) {
    AstNode* expr = parse_unary(parser);
    if (!expr) return NULL;
    
    while (match(parser, TOK_MULTIPLY) || match(parser, TOK_DIVIDE) || 
           match(parser, TOK_MODULO)) {
        TokenType op = previous(parser)->type;
        AstNode* right = parse_unary(parser);
        if (!right) {
            free_ast(expr);
            return NULL;
        }
        expr = create_binary_op(expr, right, op);
    }
    
    return expr;
}

// Parse unary
AstNode* parse_unary(Parser* parser) {
    if (match(parser, TOK_NOT) || match(parser, TOK_BITNOT) || 
        match(parser, TOK_MINUS) || match(parser, TOK_PLUS) ||
        match(parser, TOK_INCREMENT) || match(parser, TOK_DECREMENT)) {
        
        TokenType op = previous(parser)->type;
        AstNode* expr = parse_unary(parser);
        if (!expr) return NULL;
        
        return create_unary_op(expr, op);
    }
    
    return parse_postfix(parser);
}

// Parse postfix
AstNode* parse_postfix(Parser* parser) {
    AstNode* expr = parse_primary(parser);
    if (!expr) return NULL;
    
    while (1) {
        if (match(parser, TOK_LPAREN)) {
            expr = parse_function_call(parser, expr);
            if (!expr) return NULL;
        } else if (match(parser, TOK_LBRACKET)) {
            expr = parse_array_access(parser, expr);
            if (!expr) return NULL;
        } else if (match(parser, TOK_DOT) || match(parser, TOK_ARROW)) {
            expr = parse_member_access(parser, expr);
            if (!expr) return NULL;
        } else if (match(parser, TOK_INCREMENT) || match(parser, TOK_DECREMENT)) {
            TokenType op = previous(parser)->type;
            expr = create_postfix_op(expr, op);
        } else {
            break;
        }
    }
    
    return expr;
}

// Parse primary
AstNode* parse_primary(Parser* parser) {
    if (match(parser, TOK_INT_LITERAL)) {
        int value = atoi(previous(parser)->value);
        return create_int_literal(value);
    }
    
    if (match(parser, TOK_FLOAT_LITERAL)) {
        float value = atof(previous(parser)->value);
        return create_float_literal(value);
    }
    
    if (match(parser, TOK_CHAR_LITERAL)) {
        char value = previous(parser)->value[1]; // Skip quotes
        return create_char_literal(value);
    }
    
    if (match(parser, TOK_STRING_LITERAL)) {
        char* value = strdup(previous(parser)->value);
        AstNode* node = create_string_literal(value);
        free(value);
        return node;
    }
    
    if (match(parser, TOK_IDENTIFIER)) {
        char* name = strdup(previous(parser)->value);
        AstNode* node = create_identifier(name);
        free(name);
        return node;
    }
    
    if (match(parser, TOK_LPAREN)) {
        AstNode* expr = parse_expression(parser);
        if (!expr) return NULL;
        
        if (!match(parser, TOK_RPAREN)) {
            parser_error(parser, "Expected ')' after expression");
            free_ast(expr);
            return NULL;
        }
        
        return expr;
    }
    
    parser_error(parser, "Expected expression");
    return NULL;
}

// Parse function call
AstNode* parse_function_call(Parser* parser, AstNode* callee) {
    AstNode* args = parse_argument_list(parser);
    
    if (!match(parser, TOK_RPAREN)) {
        parser_error(parser, "Expected ')' after function arguments");
        if (args) free_ast(args);
        return NULL;
    }
    
    return create_function_call(callee, args);
}

// Parse array access
AstNode* parse_array_access(Parser* parser, AstNode* array) {
    AstNode* index = parse_expression(parser);
    if (!index) return NULL;
    
    if (!match(parser, TOK_RBRACKET)) {
        parser_error(parser, "Expected ']' after array index");
        free_ast(index);
        return NULL;
    }
    
    return create_array_access(array, index);
}

// Parse member access
AstNode* parse_member_access(Parser* parser, AstNode* object) {
    TokenType access_type = previous(parser)->type;
    
    if (!check(parser, TOK_IDENTIFIER)) {
        parser_error(parser, "Expected member name");
        return NULL;
    }
    
    char* member = strdup(peek(parser)->value);
    advance(parser);
    
    AstNode* result;
    if (access_type == TOK_DOT) {
        result = create_member_access(object, member);
    } else {
        result = create_pointer_access(object, member);
    }
    
    free(member);
    return result;
}

// Parse type
Type* parse_type(Parser* parser) {
    if (match(parser, TOK_INT)) {
        return create_type(TYPE_INT);
    }
    if (match(parser, TOK_FLOAT)) {
        return create_type(TYPE_FLOAT);
    }
    if (match(parser, TOK_CHAR)) {
        return create_type(TYPE_CHAR);
    }
    if (match(parser, TOK_VOID)) {
        return create_type(TYPE_VOID);
    }
    if (match(parser, TOK_DOUBLE)) {
        return create_type(TYPE_DOUBLE);
    }
    
    return NULL;
}

// Parse parameter list
AstNode* parse_parameter_list(Parser* parser) {
    AstNode* params = create_parameter_list();
    
    if (check(parser, TOK_RPAREN)) {
        return params; // Empty parameter list
    }
    
    do {
        Type* type = parse_type(parser);
        if (!type) {
            parser_error(parser, "Expected parameter type");
            free_ast(params);
            return NULL;
        }
        
        char* name = NULL;
        if (check(parser, TOK_IDENTIFIER)) {
            name = strdup(peek(parser)->value);
            advance(parser);
        }
        
        AstNode* param = create_parameter(name, type);
        add_child(params, param);
        
        if (name) free(name);
    } while (match(parser, TOK_COMMA));
    
    return params;
}

// Parse argument list
AstNode* parse_argument_list(Parser* parser) {
    AstNode* args = create_argument_list();
    
    if (check(parser, TOK_RPAREN)) {
        return args; // Empty argument list
    }
    
    do {
        AstNode* arg = parse_expression(parser);
        if (!arg) {
            free_ast(args);
            return NULL;
        }
        add_child(args, arg);
    } while (match(parser, TOK_COMMA));
    
    return args;
}
