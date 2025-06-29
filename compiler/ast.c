/*
 * AST Node Implementation - Simplified
 */

#include "ast.h"
#include <stdlib.h>
#include <string.h>
#include <stdio.h>

AstNode* create_ast_node(AstNodeType type) {
    AstNode* node = calloc(1, sizeof(AstNode));
    node->type = type;
    node->data_type = NULL;
    node->children = NULL;
    node->child_count = 0;
    node->child_capacity = 0;
    return node;
}

Type* create_type(TypeKind kind) {
    Type* type = calloc(1, sizeof(Type));
    type->base_type = kind;
    return type;
}

void free_type(Type* type) {
    if (!type) return;
    
    switch (type->base_type) {
        case TYPE_POINTER:
        case TYPE_ARRAY:
            free_type(type->element_type);
            break;
        case TYPE_STRUCT:
        case TYPE_ENUM:
            free(type->name);
            break;
        case TYPE_FUNCTION:
            free_type(type->return_type);
            break;
        default:
            break;
    }
    free(type);
}

void free_ast(AstNode* node) {
    if (!node) return;
    
    // Free children
    for (int i = 0; i < node->child_count; i++) {
        free_ast(node->children[i]);
    }
    free(node->children);
    
    // Free node-specific data
    switch (node->type) {
        case AST_STRING_LITERAL:
            free(node->data.string_literal.value);
            break;
        case AST_IDENTIFIER:
            free(node->data.identifier.name);
            break;
        case AST_MEMBER_ACCESS:
            free(node->data.member_access.member);
            break;
        case AST_POINTER_ACCESS:
            free(node->data.pointer_access.member);
            break;
        case AST_FUNCTION_DECL:
            free(node->data.function_decl.name);
            break;
        case AST_VARIABLE_DECL:
            free(node->data.variable_decl.name);
            break;
        case AST_STRUCT_DECL:
            free(node->data.struct_decl.name);
            break;
        case AST_ENUM_DECL:
            free(node->data.enum_decl.name);
            break;
        case AST_TYPEDEF_DECL:
            free(node->data.typedef_decl.name);
            break;
        case AST_PARAMETER:
            free(node->data.parameter.name);
            break;
        default:
            break;
    }
    
    free_type(node->data_type);
    free(node);
}

void print_ast(AstNode* node, int indent) {
    if (!node) return;
    
    for (int i = 0; i < indent; i++) printf("  ");
    
    switch (node->type) {
        case AST_INT_LITERAL:
            printf("IntLiteral: %d\n", node->data.int_literal.value);
            break;
        case AST_STRING_LITERAL:
            printf("StringLiteral: \"%s\"\n", node->data.string_literal.value ? node->data.string_literal.value : "");
            break;
        case AST_IDENTIFIER:
            printf("Identifier: %s\n", node->data.identifier.name ? node->data.identifier.name : "");
            break;
        case AST_BINARY_OP:
            printf("BinaryOp: %d\n", node->data.binary_op.operator);
            break;
        case AST_FUNCTION_CALL:
            printf("FunctionCall:\n");
            break;
        case AST_FUNCTION_DECL:
            printf("FunctionDecl: %s\n", node->data.function_decl.name ? node->data.function_decl.name : "");
            break;
        case AST_VARIABLE_DECL:
            printf("VarDecl: %s\n", node->data.variable_decl.name ? node->data.variable_decl.name : "");
            break;
        default:
            printf("Node type: %d\n", node->type);
            break;
    }
    
    // Print children
    for (int i = 0; i < node->child_count; i++) {
        print_ast(node->children[i], indent + 1);
    }
}

// Node creation functions for parser

// Literals
AstNode* create_int_literal(int value) {
    AstNode* node = create_ast_node(AST_INT_LITERAL);
    node->data.int_literal.value = value;
    return node;
}

AstNode* create_float_literal(float value) {
    AstNode* node = create_ast_node(AST_FLOAT_LITERAL);
    node->data.float_literal.value = value;
    return node;
}

AstNode* create_char_literal(char value) {
    AstNode* node = create_ast_node(AST_CHAR_LITERAL);
    node->data.char_literal.value = value;
    return node;
}

AstNode* create_string_literal(const char* value) {
    AstNode* node = create_ast_node(AST_STRING_LITERAL);
    node->data.string_literal.value = strdup(value);
    return node;
}

AstNode* create_identifier(const char* name) {
    AstNode* node = create_ast_node(AST_IDENTIFIER);
    node->data.identifier.name = strdup(name);
    return node;
}

// Expressions
AstNode* create_binary_op(AstNode* left, AstNode* right, TokenType operator) {
    AstNode* node = create_ast_node(AST_BINARY_OP);
    node->data.binary_op.operator = operator;
    add_child(node, left);
    add_child(node, right);
    return node;
}

AstNode* create_unary_op(AstNode* operand, TokenType operator) {
    AstNode* node = create_ast_node(AST_UNARY_OP);
    node->data.unary_op.operator = operator;
    add_child(node, operand);
    return node;
}

AstNode* create_postfix_op(AstNode* operand, TokenType operator) {
    AstNode* node = create_ast_node(AST_UNARY_OP); // Use same structure
    node->data.unary_op.operator = operator;
    add_child(node, operand);
    return node;
}

AstNode* create_assignment(AstNode* left, AstNode* right, TokenType operator) {
    AstNode* node = create_ast_node(AST_ASSIGNMENT);
    node->data.assignment.operator = operator;
    add_child(node, left);
    add_child(node, right);
    return node;
}

AstNode* create_function_call(AstNode* function, AstNode* args) {
    AstNode* node = create_ast_node(AST_FUNCTION_CALL);
    add_child(node, function);
    if (args) {
        add_child(node, args);
    }
    return node;
}

AstNode* create_array_access(AstNode* array, AstNode* index) {
    AstNode* node = create_ast_node(AST_ARRAY_ACCESS);
    add_child(node, array);
    add_child(node, index);
    return node;
}

AstNode* create_member_access(AstNode* object, const char* member) {
    AstNode* node = create_ast_node(AST_MEMBER_ACCESS);
    node->data.member_access.member = strdup(member);
    add_child(node, object);
    return node;
}

AstNode* create_pointer_access(AstNode* object, const char* member) {
    AstNode* node = create_ast_node(AST_POINTER_ACCESS);
    node->data.pointer_access.member = strdup(member);
    add_child(node, object);
    return node;
}

// Statements
AstNode* create_compound_stmt(void) {
    return create_ast_node(AST_COMPOUND_STMT);
}

AstNode* create_if_stmt(AstNode* condition, AstNode* then_stmt, AstNode* else_stmt) {
    AstNode* node = create_ast_node(AST_IF_STMT);
    add_child(node, condition);
    add_child(node, then_stmt);
    if (else_stmt) {
        add_child(node, else_stmt);
    }
    return node;
}

AstNode* create_while_stmt(AstNode* condition, AstNode* body) {
    AstNode* node = create_ast_node(AST_WHILE_STMT);
    add_child(node, condition);
    add_child(node, body);
    return node;
}

AstNode* create_for_stmt(AstNode* init, AstNode* condition, AstNode* increment, AstNode* body) {
    AstNode* node = create_ast_node(AST_FOR_STMT);
    if (init) add_child(node, init);
    if (condition) add_child(node, condition);
    if (increment) add_child(node, increment);
    add_child(node, body);
    return node;
}

AstNode* create_return_stmt(AstNode* value) {
    AstNode* node = create_ast_node(AST_RETURN_STMT);
    if (value) {
        add_child(node, value);
    }
    return node;
}

AstNode* create_break_stmt(void) {
    return create_ast_node(AST_BREAK_STMT);
}

AstNode* create_continue_stmt(void) {
    return create_ast_node(AST_CONTINUE_STMT);
}

AstNode* create_expression_stmt(AstNode* expression) {
    AstNode* node = create_ast_node(AST_EXPRESSION_STMT);
    add_child(node, expression);
    return node;
}

// Declarations
AstNode* create_function_decl(const char* name, Type* return_type, AstNode* params, AstNode* body) {
    AstNode* node = create_ast_node(AST_FUNCTION_DECL);
    node->data.function_decl.name = strdup(name);
    node->data.function_decl.return_type = return_type;
    if (params) add_child(node, params);
    if (body) add_child(node, body);
    return node;
}

AstNode* create_variable_decl(const char* name, Type* type, AstNode* initializer) {
    AstNode* node = create_ast_node(AST_VARIABLE_DECL);
    node->data.variable_decl.name = strdup(name);
    node->data.variable_decl.type = type;
    if (initializer) {
        add_child(node, initializer);
    }
    return node;
}

AstNode* create_struct_decl(const char* name, AstNode* fields) {
    AstNode* node = create_ast_node(AST_STRUCT_DECL);
    node->data.struct_decl.name = strdup(name);
    if (fields) add_child(node, fields);
    return node;
}

AstNode* create_enum_decl(const char* name, AstNode* values) {
    AstNode* node = create_ast_node(AST_ENUM_DECL);
    node->data.enum_decl.name = strdup(name);
    if (values) add_child(node, values);
    return node;
}

AstNode* create_typedef_decl(const char* name, Type* type) {
    AstNode* node = create_ast_node(AST_TYPEDEF_DECL);
    node->data.typedef_decl.name = strdup(name);
    node->data.typedef_decl.type = type;
    return node;
}

// Helpers
AstNode* create_parameter_list(void) {
    return create_ast_node(AST_PARAMETER_LIST);
}

AstNode* create_argument_list(void) {
    return create_ast_node(AST_ARGUMENT_LIST);
}

AstNode* create_parameter(const char* name, Type* type) {
    AstNode* node = create_ast_node(AST_PARAMETER);
    if (name) {
        node->data.parameter.name = strdup(name);
    }
    node->data.parameter.type = type;
    return node;
}

// Add child to node
void add_child(AstNode* parent, AstNode* child) {
    if (!parent || !child) return;
    
    if (parent->child_count >= parent->child_capacity) {
        parent->child_capacity = parent->child_capacity ? parent->child_capacity * 2 : 4;
        parent->children = realloc(parent->children, parent->child_capacity * sizeof(AstNode*));
    }
    
    parent->children[parent->child_count++] = child;
}

// Type creation helpers
Type* create_pointer_type(Type* base_type) {
    Type* type = create_type(TYPE_POINTER);
    type->element_type = base_type;
    return type;
}

Type* create_array_type(Type* element_type, int size) {
    Type* type = create_type(TYPE_ARRAY);
    type->element_type = element_type;
    type->array_size = size;
    return type;
}

Type* create_function_type(Type* return_type) {
    Type* type = create_type(TYPE_FUNCTION);
    type->return_type = return_type;
    return type;
}

Type* create_struct_type(const char* name) {
    Type* type = create_type(TYPE_STRUCT);
    type->name = strdup(name);
    return type;
}

Type* create_enum_type(const char* name) {
    Type* type = create_type(TYPE_ENUM);
    type->name = strdup(name);
    return type;
}
