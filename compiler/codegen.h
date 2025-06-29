/*
 * Code Generator - Emits custom RISC assembly from AST
 */

#ifndef CODEGEN_H
#define CODEGEN_H

#include <stdio.h>
#include "ast.h"
#include "type_checker.h"

// Code generation context
typedef struct CodegenContext {
    FILE* output;
    SymbolTable* symbols;
    int label_counter;
    int temp_counter;
    int current_function_offset;
    int break_label;
    int continue_label;
} CodegenContext;

// Main code generation function
int generate_code(AstNode* ast, SymbolTable* symbols, FILE* output);

// Code generation for different node types
void codegen_node(AstNode* node, CodegenContext* ctx);
void codegen_declaration(AstNode* decl, CodegenContext* ctx);
void codegen_function_decl(AstNode* func, CodegenContext* ctx);
void codegen_variable_decl(AstNode* var, CodegenContext* ctx);
void codegen_statement(AstNode* stmt, CodegenContext* ctx);
void codegen_expression(AstNode* expr, CodegenContext* ctx, const char* result_reg);

// Expression code generation
void codegen_binary_op(AstNode* expr, CodegenContext* ctx, const char* result_reg);
void codegen_unary_op(AstNode* expr, CodegenContext* ctx, const char* result_reg);
void codegen_assignment(AstNode* expr, CodegenContext* ctx, const char* result_reg);
void codegen_function_call(AstNode* expr, CodegenContext* ctx, const char* result_reg);
void codegen_identifier(AstNode* expr, CodegenContext* ctx, const char* result_reg);
void codegen_literal(AstNode* expr, CodegenContext* ctx, const char* result_reg);

// Control flow
void codegen_if_stmt(AstNode* stmt, CodegenContext* ctx);
void codegen_while_stmt(AstNode* stmt, CodegenContext* ctx);
void codegen_for_stmt(AstNode* stmt, CodegenContext* ctx);
void codegen_return_stmt(AstNode* stmt, CodegenContext* ctx);

// Utility functions
int get_next_label(CodegenContext* ctx);
const char* get_temp_register(CodegenContext* ctx);
void emit_label(CodegenContext* ctx, int label);
void emit_instruction(CodegenContext* ctx, const char* op, const char* args, ...);
void emit_comment(CodegenContext* ctx, const char* comment);

// Runtime functions
void emit_runtime_functions(CodegenContext* ctx);

#endif
