/*
 * Parser - Converts tokens to Abstract Syntax Tree
 * Implements recursive descent parser for C language subset
 */

#ifndef PARSER_H
#define PARSER_H

#include "lexer.h"
#include "ast.h"

// Parser state
typedef struct {
    TokenList* tokens;
    int current;
    int had_error;
} Parser;

// Parser functions
AstNode* parse(TokenList* tokens);
void parser_error(Parser* parser, const char* message);

// Helper functions for parsing
int match(Parser* parser, TokenType type);
int check(Parser* parser, TokenType type);
Token* advance(Parser* parser);
Token* peek(Parser* parser);
Token* previous(Parser* parser);
int is_at_end(Parser* parser);

// Grammar rules
AstNode* parse_program(Parser* parser);
AstNode* parse_declaration(Parser* parser);
AstNode* parse_function_declaration(Parser* parser);
AstNode* parse_variable_declaration(Parser* parser);
AstNode* parse_struct_declaration(Parser* parser);
AstNode* parse_enum_declaration(Parser* parser);
AstNode* parse_typedef_declaration(Parser* parser);

AstNode* parse_statement(Parser* parser);
AstNode* parse_compound_statement(Parser* parser);
AstNode* parse_if_statement(Parser* parser);
AstNode* parse_while_statement(Parser* parser);
AstNode* parse_for_statement(Parser* parser);
AstNode* parse_switch_statement(Parser* parser);
AstNode* parse_case_statement(Parser* parser);
AstNode* parse_default_statement(Parser* parser);
AstNode* parse_return_statement(Parser* parser);
AstNode* parse_break_statement(Parser* parser);
AstNode* parse_continue_statement(Parser* parser);
AstNode* parse_expression_statement(Parser* parser);

AstNode* parse_expression(Parser* parser);
AstNode* parse_assignment(Parser* parser);
AstNode* parse_logical_or(Parser* parser);
AstNode* parse_logical_and(Parser* parser);
AstNode* parse_bitwise_or(Parser* parser);
AstNode* parse_bitwise_xor(Parser* parser);
AstNode* parse_bitwise_and(Parser* parser);
AstNode* parse_equality(Parser* parser);
AstNode* parse_comparison(Parser* parser);
AstNode* parse_shift(Parser* parser);
AstNode* parse_term(Parser* parser);
AstNode* parse_factor(Parser* parser);
AstNode* parse_unary(Parser* parser);
AstNode* parse_postfix(Parser* parser);
AstNode* parse_primary(Parser* parser);

AstNode* parse_function_call(Parser* parser, AstNode* callee);
AstNode* parse_array_access(Parser* parser, AstNode* array);
AstNode* parse_member_access(Parser* parser, AstNode* object);

Type* parse_type(Parser* parser);
AstNode* parse_parameter_list(Parser* parser);
AstNode* parse_argument_list(Parser* parser);
AstNode* parse_array_initializer(Parser* parser);

const char* token_type_name(TokenType type);

#endif
