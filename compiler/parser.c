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

// Forward declarations for recursive functions
AstNode* parse_ternary(Parser* parser);
AstNode* parse_logical_or(Parser* parser);

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
            // Synchronize after error - ensure we make progress
            int old_current = parser->current;
            while (!is_at_end(parser) && !check(parser, TOK_SEMICOLON) && 
                   !check(parser, TOK_LBRACE) && !check(parser, TOK_RBRACE)) {
                advance(parser);
            }
            if (check(parser, TOK_SEMICOLON)) advance(parser);
            // If we didn't make any progress, force advance to prevent infinite loop
            if (parser->current == old_current && !is_at_end(parser)) {
                advance(parser);
            }
            parser->had_error = 0; // Reset error state
        } else {
            // If no declaration was parsed and no error was set, break to avoid infinite loop
            break;
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
    
    // Check for array declaration: int arr[size] or int arr[]
    if (match(parser, TOK_LBRACKET)) {
        int array_size = 0;
        
        if (check(parser, TOK_INT_LITERAL)) {
            array_size = atoi(peek(parser)->value);
            advance(parser);
        } else if (!check(parser, TOK_RBRACKET)) {
            parser_error(parser, "Expected array size or ']'");
            free(name);
            free_type(type);
            return NULL;
        }
        
        if (!match(parser, TOK_RBRACKET)) {
            parser_error(parser, "Expected ']' after array size");
            free(name);
            free_type(type);
            return NULL;
        }
        
        // Create array type (size will be determined later if 0 and there's an initializer)
        Type* array_type = create_array_type(type, array_size);
        type = array_type;
    }
    
    AstNode* initializer = NULL;
    if (match(parser, TOK_ASSIGN)) {
        // Check for array initializer: {1, 2, 3}
        if (check(parser, TOK_LBRACE) && type->base_type == TYPE_ARRAY) {
            initializer = parse_array_initializer(parser);
        } else {
            initializer = parse_expression(parser);
        }
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
        check(parser, TOK_DOUBLE) || check(parser, TOK_VOID) || check(parser, TOK_BOOL)) {
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
    if (check(parser, TOK_SWITCH)) {
        return parse_switch_statement(parser);
    }
    if (check(parser, TOK_CASE)) {
        return parse_case_statement(parser);
    }
    if (check(parser, TOK_DEFAULT)) {
        return parse_default_statement(parser);
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
            // Error recovery - ensure we make progress to avoid infinite loops
            int old_current = parser->current;
            while (!is_at_end(parser) && !check(parser, TOK_SEMICOLON) && 
                   !check(parser, TOK_RBRACE)) {
                advance(parser);
            }
            if (check(parser, TOK_SEMICOLON)) advance(parser);
            // If we didn't make any progress, force advance to prevent infinite loop
            if (parser->current == old_current && !is_at_end(parser)) {
                advance(parser);
            }
            parser->had_error = 0;
        } else {
            // If no statement was parsed and no error was set, we need to break
            // to avoid infinite loop
            break;
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

// Parse switch statement
AstNode* parse_switch_statement(Parser* parser) {
    advance(parser); // consume 'switch'
    
    if (!match(parser, TOK_LPAREN)) {
        parser_error(parser, "Expected '(' after 'switch'");
        return NULL;
    }
    
    AstNode* condition = parse_expression(parser);
    if (!condition) return NULL;
    
    if (!match(parser, TOK_RPAREN)) {
        parser_error(parser, "Expected ')' after switch condition");
        free_ast(condition);
        return NULL;
    }
    
    if (!match(parser, TOK_LBRACE)) {
        parser_error(parser, "Expected '{' after switch statement");
        free_ast(condition);
        return NULL;
    }
    
    AstNode* body = create_compound_stmt();
    AstNode* switch_stmt = create_switch_stmt(condition, body);
    
    while (!is_at_end(parser) && !check(parser, TOK_RBRACE)) {
        AstNode* case_stmt = parse_case_statement(parser);
        if (case_stmt) {
            add_child(body, case_stmt);
        } else if (parser->had_error) {
            // Error recovery - ensure we make progress
            int old_current = parser->current;
            while (!is_at_end(parser) && !check(parser, TOK_RBRACE) && 
                   !check(parser, TOK_CASE) && !check(parser, TOK_DEFAULT)) {
                advance(parser);
            }
            // If we didn't make any progress, force advance to prevent infinite loop
            if (parser->current == old_current && !is_at_end(parser)) {
                advance(parser);
            }
            parser->had_error = 0;
        } else {
            // If no case statement was parsed and no error was set, break to avoid infinite loop
            break;
        }
    }
    
    if (!match(parser, TOK_RBRACE)) {
        parser_error(parser, "Expected '}' after switch statement");
        free_ast(switch_stmt);
        return NULL;
    }
    
    return switch_stmt;
}

// Parse case statement
AstNode* parse_case_statement(Parser* parser) {
    advance(parser); // consume 'case'
    
    AstNode* value = parse_expression(parser);
    if (!value) return NULL;
    
    if (!match(parser, TOK_COLON)) {
        parser_error(parser, "Expected ':' after case value");
        free_ast(value);
        return NULL;
    }
    
    AstNode* stmt = parse_statement(parser);
    if (!stmt) {
        free_ast(value);
        return NULL;
    }
    
    return create_case_stmt(value, stmt);
}

// Parse default statement
AstNode* parse_default_statement(Parser* parser) {
    advance(parser); // consume 'default'
    
    if (!match(parser, TOK_COLON)) {
        parser_error(parser, "Expected ':' after default");
        return NULL;
    }
    
    AstNode* stmt = parse_statement(parser);
    if (!stmt) {
        return NULL;
    }
    
    return create_default_stmt(stmt);
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
    AstNode* expr = parse_ternary(parser);
    if (!expr) return NULL;
    
    if (match(parser, TOK_ASSIGN) || match(parser, TOK_PLUS_ASSIGN) || 
        match(parser, TOK_MINUS_ASSIGN) || match(parser, TOK_MUL_ASSIGN) || 
        match(parser, TOK_DIV_ASSIGN) || match(parser, TOK_MOD_ASSIGN) ||
        match(parser, TOK_AND_ASSIGN) || match(parser, TOK_OR_ASSIGN) ||
        match(parser, TOK_XOR_ASSIGN) || match(parser, TOK_SHL_ASSIGN) ||
        match(parser, TOK_SHR_ASSIGN)) {
        
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

// Parse ternary operator (condition ? true_expr : false_expr)
AstNode* parse_ternary(Parser* parser) {
    AstNode* expr = parse_logical_or(parser);
    if (!expr) return NULL;
    
    if (match(parser, TOK_QUESTION)) {
        AstNode* true_expr = parse_expression(parser);
        if (!true_expr) {
            free_ast(expr);
            return NULL;
        }
        
        if (!match(parser, TOK_COLON)) {
            parser_error(parser, "Expected ':' in ternary operator");
            free_ast(expr);
            free_ast(true_expr);
            return NULL;
        }
        
        AstNode* false_expr = parse_ternary(parser); // Right associative
        if (!false_expr) {
            free_ast(expr);
            free_ast(true_expr);
            return NULL;
        }
        
        return create_ternary_op(expr, true_expr, false_expr);
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
    
    if (match(parser, TOK_BOOL_LITERAL)) {
        Token* token = previous(parser);
        int value = (strcmp(token->value, "true") == 0) ? 1 : 0;
        return create_bool_literal(value);
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
    Type* base = NULL;
    if (match(parser, TOK_INT)) {
        base = create_type(TYPE_INT);
    } else if (match(parser, TOK_FLOAT)) {
        base = create_type(TYPE_FLOAT);
    } else if (match(parser, TOK_CHAR)) {
        base = create_type(TYPE_CHAR);
    } else if (match(parser, TOK_VOID)) {
        base = create_type(TYPE_VOID);
    } else if (match(parser, TOK_DOUBLE)) {
        base = create_type(TYPE_DOUBLE);
    } else if (match(parser, TOK_BOOL)) {
        base = create_type(TYPE_BOOL);
    } else if (match(parser, TOK_IDENTIFIER)) {
        // Support typedefs and custom types (e.g., uint8_t)
        char* name = strdup(previous(parser)->value);
        base = create_custom_type(name);
        free(name);
    }
    if (!base) return NULL;
    // Handle pointer types: int*, uint8_t*, etc.
    while (match(parser, TOK_MULTIPLY)) {
        base = create_pointer_type(base);
    }
    return base;
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
            // Error recovery: advance to avoid infinite loop
            if (!is_at_end(parser)) {
                advance(parser);
            }
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

        if (!match(parser, TOK_COMMA)) {
            break;
        }
        
        // Handle trailing comma: if next token is ')', break out of loop
        if (check(parser, TOK_RPAREN)) {
            break;
        }
    } while (!is_at_end(parser));
    
    return params;
}

// Parse argument list
AstNode* parse_argument_list(Parser* parser) {
    AstNode* args = create_argument_list();
    
    if (check(parser, TOK_RPAREN)) {
        return args; // Empty argument list
    }
     do {
        AstNode* expr = parse_expression(parser);
        if (!expr) {
            // Error recovery: advance to avoid infinite loop
            if (!is_at_end(parser)) {
                advance(parser);
            }
            free_ast(args);
            return NULL;
        }
        add_child(args, expr);

        if (!match(parser, TOK_COMMA)) {
            break;
        }
        
        // Handle trailing comma: if next token is ')', break out of loop
        if (check(parser, TOK_RPAREN)) {
            break;
        }
    } while (!is_at_end(parser));
    
    return args;
}

// Parse array initializer: {expr1, expr2, expr3}
AstNode* parse_array_initializer(Parser* parser) {
    if (!match(parser, TOK_LBRACE)) {
        parser_error(parser, "Expected '{' for array initializer");
        return NULL;
    }
    
    AstNode* initializer = create_array_initializer();
    
    if (match(parser, TOK_RBRACE)) {
        return initializer; // Empty initializer
    }
    do {
        AstNode* expr = parse_expression(parser);
        if (!expr) {
            // Error recovery: advance to avoid infinite loop
            if (!is_at_end(parser)) {
                advance(parser);
            }
            free_ast(initializer);
            return NULL;
        }
        add_child(initializer, expr);

        if (!match(parser, TOK_COMMA)) {
            break;
        }
        
        // Handle trailing comma: if next token is '}', break out of loop
        if (check(parser, TOK_RBRACE)) {
            break;
        }
    } while (!is_at_end(parser));
    
    if (!match(parser, TOK_RBRACE)) {
        parser_error(parser, "Expected '}' after array initializer");
        free_ast(initializer);
        return NULL;
    }
    
    return initializer;
}