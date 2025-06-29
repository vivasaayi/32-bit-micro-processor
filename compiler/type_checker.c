/*
 * Type Checker Implementation
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "type_checker.h"

// Hash function for symbol table
unsigned int hash_string(const char* str) {
    unsigned int hash = 5381;
    while (*str) {
        hash = ((hash << 5) + hash) + *str++;
    }
    return hash % SYMBOL_TABLE_SIZE;
}

// Create a new symbol table
SymbolTable* create_symbol_table(void) {
    SymbolTable* table = malloc(sizeof(SymbolTable));
    memset(table->buckets, 0, sizeof(table->buckets));
    table->parent = NULL;
    return table;
}

// Free symbol table and all symbols
void free_symbol_table(SymbolTable* table) {
    if (!table) return;
    
    for (int i = 0; i < SYMBOL_TABLE_SIZE; i++) {
        Symbol* symbol = table->buckets[i];
        while (symbol) {
            Symbol* next = symbol->next;
            free(symbol->name);
            // Don't free type here - it's owned by AST
            free(symbol);
            symbol = next;
        }
    }
    
    free(table);
}

// Push a new scope (create child symbol table)
SymbolTable* push_scope(SymbolTable* current) {
    SymbolTable* new_scope = create_symbol_table();
    new_scope->parent = current;
    return new_scope;
}

// Pop scope (return to parent)
SymbolTable* pop_scope(SymbolTable* current) {
    if (!current) return NULL;
    SymbolTable* parent = current->parent;
    free_symbol_table(current);
    return parent;
}

// Lookup symbol in current scope and parent scopes
Symbol* lookup_symbol(SymbolTable* table, const char* name) {
    while (table) {
        Symbol* symbol = lookup_symbol_local(table, name);
        if (symbol) return symbol;
        table = table->parent;
    }
    return NULL;
}

// Lookup symbol only in current scope
Symbol* lookup_symbol_local(SymbolTable* table, const char* name) {
    if (!table || !name) return NULL;
    
    unsigned int hash = hash_string(name);
    Symbol* symbol = table->buckets[hash];
    
    while (symbol) {
        if (strcmp(symbol->name, name) == 0) {
            return symbol;
        }
        symbol = symbol->next;
    }
    
    return NULL;
}

// Add symbol to current scope
int add_symbol(SymbolTable* table, const char* name, SymbolType symbol_type,
               Type* type, AstNode* declaration) {
    if (!table || !name) return 0;
    
    // Check if symbol already exists in current scope
    if (lookup_symbol_local(table, name)) {
        printf("Error: Symbol '%s' already declared in current scope\n", name);
        return 0;
    }
    
    // Create new symbol
    Symbol* symbol = malloc(sizeof(Symbol));
    symbol->name = strdup(name);
    symbol->symbol_type = symbol_type;
    symbol->type = type;
    symbol->declaration = declaration;
    
    // Add to hash table
    unsigned int hash = hash_string(name);
    symbol->next = table->buckets[hash];
    table->buckets[hash] = symbol;
    
    return 1;
}

// Main type checking function
int type_check(AstNode* ast, SymbolTable* symbols) {
    if (!ast || !symbols) return 0;
    
    return type_check_node(ast, symbols);
}

// Type check a single node
int type_check_node(AstNode* node, SymbolTable* symbols) {
    if (!node) return 1;
    
    switch (node->type) {
        case AST_COMPOUND_STMT:
            // Create new scope for compound statement
            symbols = push_scope(symbols);
            for (int i = 0; i < node->child_count; i++) {
                if (!type_check_node(node->children[i], symbols)) {
                    symbols = pop_scope(symbols);
                    return 0;
                }
            }
            symbols = pop_scope(symbols);
            return 1;
            
        case AST_FUNCTION_DECL:
        case AST_VARIABLE_DECL:
        case AST_STRUCT_DECL:
        case AST_ENUM_DECL:
        case AST_TYPEDEF_DECL:
            return type_check_declaration(node, symbols);
            
        case AST_IF_STMT:
        case AST_WHILE_STMT:
        case AST_FOR_STMT:
        case AST_RETURN_STMT:
        case AST_BREAK_STMT:
        case AST_CONTINUE_STMT:
        case AST_EXPRESSION_STMT:
            return type_check_statement(node, symbols);
            
        case AST_BINARY_OP:
        case AST_TERNARY_OP:
        case AST_UNARY_OP:
        case AST_ASSIGNMENT:
        case AST_FUNCTION_CALL:
        case AST_MEMBER_ACCESS:
        case AST_POINTER_ACCESS:
        case AST_ARRAY_ACCESS:
        case AST_INT_LITERAL:
        case AST_FLOAT_LITERAL:
        case AST_CHAR_LITERAL:
        case AST_STRING_LITERAL:
        case AST_IDENTIFIER: {
            Type* result_type;
            return type_check_expression(node, symbols, &result_type);
        }
        
        default:
            // For other node types, just check children
            for (int i = 0; i < node->child_count; i++) {
                if (!type_check_node(node->children[i], symbols)) {
                    return 0;
                }
            }
            return 1;
    }
}

// Type check expression
int type_check_expression(AstNode* expr, SymbolTable* symbols, Type** result_type) {
    if (!expr) {
        *result_type = NULL;
        return 0;
    }
    
    switch (expr->type) {
        case AST_INT_LITERAL:
            *result_type = create_type(TYPE_INT);
            return 1;
            
        case AST_FLOAT_LITERAL:
            *result_type = create_type(TYPE_FLOAT);
            return 1;
            
        case AST_CHAR_LITERAL:
            *result_type = create_type(TYPE_CHAR);
            return 1;
            
        case AST_STRING_LITERAL:
            *result_type = create_pointer_type(create_type(TYPE_CHAR));
            return 1;
            
        case AST_IDENTIFIER: {
            Symbol* symbol = lookup_symbol(symbols, expr->data.identifier.name);
            if (!symbol) {
                printf("Error: Undefined identifier '%s'\n", expr->data.identifier.name);
                *result_type = NULL;
                return 0;
            }
            *result_type = symbol->type;
            return 1;
        }
        
        case AST_BINARY_OP: {
            Type* left_type, *right_type;
            if (!type_check_expression(expr->children[0], symbols, &left_type) ||
                !type_check_expression(expr->children[1], symbols, &right_type)) {
                *result_type = NULL;
                return 0;
            }
            
            // Check type compatibility based on operator
            switch (expr->data.binary_op.operator) {
                case TOK_PLUS:
                case TOK_MINUS:
                case TOK_MULTIPLY:
                case TOK_DIVIDE:
                case TOK_MODULO:
                    if (!types_compatible(left_type, right_type)) {
                        printf("Error: Incompatible types in arithmetic operation\n");
                        *result_type = NULL;
                        return 0;
                    }
                    *result_type = get_common_type(left_type, right_type);
                    return 1;
                    
                case TOK_EQ:
                case TOK_NE:
                case TOK_LT:
                case TOK_LE:
                case TOK_GT:
                case TOK_GE:
                    if (!types_compatible(left_type, right_type)) {
                        printf("Error: Incompatible types in comparison\n");
                        *result_type = NULL;
                        return 0;
                    }
                    *result_type = create_type(TYPE_INT); // Boolean result
                    return 1;
                    
                case TOK_AND:
                case TOK_OR:
                    *result_type = create_type(TYPE_INT); // Boolean result
                    return 1;
                    
                case TOK_BITAND:
                case TOK_BITOR:
                case TOK_BITXOR:
                case TOK_SHL:
                case TOK_SHR:
                    if (left_type->base_type != TYPE_INT || right_type->base_type != TYPE_INT) {
                        printf("Error: Bitwise operations require integer types\n");
                        *result_type = NULL;
                        return 0;
                    }
                    *result_type = create_type(TYPE_INT);
                    return 1;
                    
                default:
                    printf("Error: Unknown binary operator\n");
                    *result_type = NULL;
                    return 0;
            }
        }
        
        case AST_TERNARY_OP: {
            Type* condition_type, *true_type, *false_type;
            
            // Type check all three expressions
            if (!type_check_expression(expr->children[0], symbols, &condition_type) ||
                !type_check_expression(expr->children[1], symbols, &true_type) ||
                !type_check_expression(expr->children[2], symbols, &false_type)) {
                *result_type = NULL;
                return 0;
            }
            
            // Condition should be evaluable as boolean (any numeric type)
            if (condition_type->base_type != TYPE_INT && 
                condition_type->base_type != TYPE_FLOAT &&
                condition_type->base_type != TYPE_CHAR) {
                printf("Error: Ternary condition must be numeric type\n");
                *result_type = NULL;
                return 0;
            }
            
            // True and false expressions should be compatible
            if (!types_compatible(true_type, false_type)) {
                printf("Error: Incompatible types in ternary true/false expressions\n");
                *result_type = NULL;
                return 0;
            }
            
            // Result type is the common type of true/false expressions
            *result_type = get_common_type(true_type, false_type);
            return 1;
        }
        
        case AST_UNARY_OP: {
            Type* operand_type;
            if (!type_check_expression(expr->children[0], symbols, &operand_type)) {
                *result_type = NULL;
                return 0;
            }
            
            switch (expr->data.unary_op.operator) {
                case TOK_MINUS:
                case TOK_PLUS:
                    if (operand_type->base_type != TYPE_INT && operand_type->base_type != TYPE_FLOAT) {
                        printf("Error: Unary +/- requires numeric type\n");
                        *result_type = NULL;
                        return 0;
                    }
                    *result_type = operand_type;
                    return 1;
                    
                case TOK_NOT:
                    *result_type = create_type(TYPE_INT); // Boolean result
                    return 1;
                    
                case TOK_BITNOT:
                    if (operand_type->base_type != TYPE_INT) {
                        printf("Error: Bitwise NOT requires integer type\n");
                        *result_type = NULL;
                        return 0;
                    }
                    *result_type = create_type(TYPE_INT);
                    return 1;
                    
                case TOK_INCREMENT:
                case TOK_DECREMENT:
                    if (operand_type->base_type != TYPE_INT && operand_type->base_type != TYPE_FLOAT) {
                        printf("Error: Increment/decrement requires numeric type\n");
                        *result_type = NULL;
                        return 0;
                    }
                    *result_type = operand_type;
                    return 1;
                    
                default:
                    printf("Error: Unknown unary operator\n");
                    *result_type = NULL;
                    return 0;
            }
        }
        
        case AST_ASSIGNMENT: {
            Type* left_type, *right_type;
            if (!type_check_expression(expr->children[0], symbols, &left_type) ||
                !type_check_expression(expr->children[1], symbols, &right_type)) {
                *result_type = NULL;
                return 0;
            }
            
            TokenType op = expr->data.assignment.operator;
            
            if (op == TOK_ASSIGN) {
                // Regular assignment - just check type compatibility
                if (!types_compatible(left_type, right_type)) {
                    printf("Error: Incompatible types in assignment\n");
                    *result_type = NULL;
                    return 0;
                }
            } else {
                // Compound assignment - check that the operation is valid
                // For compound assignments like +=, -=, *=, /=, both operands should be numeric
                if ((left_type->base_type != TYPE_INT && left_type->base_type != TYPE_FLOAT && left_type->base_type != TYPE_CHAR) ||
                    (right_type->base_type != TYPE_INT && right_type->base_type != TYPE_FLOAT && right_type->base_type != TYPE_CHAR)) {
                    printf("Error: Compound assignment requires numeric types\n");
                    *result_type = NULL;
                    return 0;
                }
                
                // Check type compatibility for the operation
                if (!types_compatible(left_type, right_type)) {
                    printf("Error: Incompatible types in compound assignment\n");
                    *result_type = NULL;
                    return 0;
                }
            }
            
            *result_type = left_type;
            return 1;
        }
        
        case AST_FUNCTION_CALL: {
            Type* func_type;
            if (!type_check_expression(expr->children[0], symbols, &func_type)) {
                *result_type = NULL;
                return 0;
            }
            
            // Check if it's a function symbol
            if (expr->children[0]->type == AST_IDENTIFIER) {
                Symbol* symbol = lookup_symbol(symbols, expr->children[0]->data.identifier.name);
                if (symbol && symbol->symbol_type == SYMBOL_FUNCTION) {
                    *result_type = symbol->type; // Return type of function
                    return 1;
                }
            }
            
            if (func_type->base_type != TYPE_FUNCTION) {
                printf("Error: Attempting to call non-function\n");
                *result_type = NULL;
                return 0;
            }
            
            // Type check arguments (simplified)
            if (expr->child_count > 1) {
                for (int i = 1; i < expr->child_count; i++) {
                    Type* arg_type;
                    if (!type_check_expression(expr->children[i], symbols, &arg_type)) {
                        *result_type = NULL;
                        return 0;
                    }
                }
            }
            
            *result_type = func_type->return_type;
            return 1;
        }
        
        case AST_ARRAY_ACCESS: {
            Type* array_type, *index_type;
            if (!type_check_expression(expr->children[0], symbols, &array_type) ||
                !type_check_expression(expr->children[1], symbols, &index_type)) {
                *result_type = NULL;
                return 0;
            }
            
            if (array_type->base_type != TYPE_ARRAY && array_type->base_type != TYPE_POINTER) {
                printf("Error: Array access on non-array type\n");
                *result_type = NULL;
                return 0;
            }
            
            if (index_type->base_type != TYPE_INT) {
                printf("Error: Array index must be integer\n");
                *result_type = NULL;
                return 0;
            }
            
            *result_type = array_type->element_type;
            return 1;
        }
        
        case AST_MEMBER_ACCESS:
        case AST_POINTER_ACCESS:
            // Simplified - just return int type for now
            *result_type = create_type(TYPE_INT);
            return 1;
            
        default:
            printf("Error: Unknown expression type in type checker\n");
            *result_type = NULL;
            return 0;
    }
}

// Type check statement
int type_check_statement(AstNode* stmt, SymbolTable* symbols) {
    if (!stmt) return 1;
    
    switch (stmt->type) {
        case AST_IF_STMT:
            // Check condition
            if (stmt->child_count > 0) {
                Type* condition_type;
                if (!type_check_expression(stmt->children[0], symbols, &condition_type)) {
                    return 0;
                }
            }
            // Check then and else branches
            for (int i = 1; i < stmt->child_count; i++) {
                if (!type_check_node(stmt->children[i], symbols)) {
                    return 0;
                }
            }
            return 1;
            
        case AST_WHILE_STMT:
            // Check condition
            if (stmt->child_count > 0) {
                Type* condition_type;
                if (!type_check_expression(stmt->children[0], symbols, &condition_type)) {
                    return 0;
                }
            }
            // Check body
            if (stmt->child_count > 1) {
                return type_check_node(stmt->children[1], symbols);
            }
            return 1;
            
        case AST_FOR_STMT:
            // Simplified - just check body
            if (stmt->child_count > 0) {
                return type_check_node(stmt->children[stmt->child_count - 1], symbols);
            }
            return 1;
            
        case AST_RETURN_STMT:
            // Check return value if present
            if (stmt->child_count > 0) {
                Type* return_type;
                return type_check_expression(stmt->children[0], symbols, &return_type);
            }
            return 1;
            
        case AST_EXPRESSION_STMT:
            if (stmt->child_count > 0) {
                Type* expr_type;
                return type_check_expression(stmt->children[0], symbols, &expr_type);
            }
            return 1;
            
        case AST_BREAK_STMT:
        case AST_CONTINUE_STMT:
            return 1;
            
        default:
            return type_check_node(stmt, symbols);
    }
}

// Type check declaration
int type_check_declaration(AstNode* decl, SymbolTable* symbols) {
    if (!decl) return 1;
    
    switch (decl->type) {
        case AST_FUNCTION_DECL: {
            const char* name = decl->data.function_decl.name;
            Type* return_type = decl->data.function_decl.return_type;
            
            // Add function to symbol table
            if (!add_symbol(symbols, name, SYMBOL_FUNCTION, return_type, decl)) {
                return 0;
            }
            
            // Type check function body if present
            if (decl->child_count > 1) {
                // Create new scope for function
                SymbolTable* func_scope = push_scope(symbols);
                
                // Add parameters to function scope
                AstNode* params = decl->children[0];
                if (params) {
                    for (int i = 0; i < params->child_count; i++) {
                        AstNode* param = params->children[i];
                        if (param->type == AST_PARAMETER) {
                            const char* param_name = param->data.parameter.name;
                            Type* param_type = param->data.parameter.type;
                            if (param_name && !add_symbol(func_scope, param_name, SYMBOL_VARIABLE, param_type, param)) {
                                func_scope = pop_scope(func_scope);
                                return 0;
                            }
                        }
                    }
                }
                
                // Type check function body
                int result = type_check_node(decl->children[1], func_scope);
                func_scope = pop_scope(func_scope);
                return result;
            }
            
            return 1;
        }
        
        case AST_VARIABLE_DECL: {
            const char* name = decl->data.variable_decl.name;
            Type* var_type = decl->data.variable_decl.type;
            
            // Add variable to symbol table
            if (!add_symbol(symbols, name, SYMBOL_VARIABLE, var_type, decl)) {
                return 0;
            }
            
            // Type check initializer if present
            if (decl->child_count > 0) {
                Type* init_type;
                if (!type_check_expression(decl->children[0], symbols, &init_type)) {
                    return 0;
                }
                
                if (!types_compatible(var_type, init_type)) {
                    printf("Error: Incompatible types in variable initialization\n");
                    return 0;
                }
            }
            
            return 1;
        }
        
        case AST_STRUCT_DECL: {
            const char* name = decl->data.struct_decl.name;
            Type* struct_type = create_struct_type(name);
            
            return add_symbol(symbols, name, SYMBOL_STRUCT, struct_type, decl);
        }
        
        case AST_ENUM_DECL: {
            const char* name = decl->data.enum_decl.name;
            Type* enum_type = create_enum_type(name);
            
            return add_symbol(symbols, name, SYMBOL_ENUM, enum_type, decl);
        }
        
        case AST_TYPEDEF_DECL: {
            const char* name = decl->data.typedef_decl.name;
            Type* aliased_type = decl->data.typedef_decl.type;
            
            return add_symbol(symbols, name, SYMBOL_TYPEDEF, aliased_type, decl);
        }
        
        default:
            printf("Error: Unknown declaration type\n");
            return 0;
    }
}

// Check if two types are compatible (for assignments, etc.)
int types_compatible(Type* t1, Type* t2) {
    if (!t1 || !t2) return 0;
    
    // Exact match
    if (types_equal(t1, t2)) return 1;
    
    // Numeric conversions
    if ((t1->base_type == TYPE_INT || t1->base_type == TYPE_FLOAT || t1->base_type == TYPE_CHAR) &&
        (t2->base_type == TYPE_INT || t2->base_type == TYPE_FLOAT || t2->base_type == TYPE_CHAR)) {
        return 1;
    }
    
    return 0;
}

// Check if two types are exactly equal
int types_equal(Type* t1, Type* t2) {
    if (!t1 || !t2) return 0;
    
    if (t1->base_type != t2->base_type) return 0;
    
    switch (t1->base_type) {
        case TYPE_ARRAY:
            return types_equal(t1->element_type, t2->element_type) &&
                   t1->array_size == t2->array_size;
                   
        case TYPE_POINTER:
            return types_equal(t1->element_type, t2->element_type);
            
        case TYPE_FUNCTION:
            return types_equal(t1->return_type, t2->return_type);
            // TODO: Check parameter types
            
        case TYPE_STRUCT:
        case TYPE_ENUM:
            return strcmp(t1->name, t2->name) == 0;
            
        default:
            return 1; // Basic types are equal if base_type matches
    }
}

// Get common type for arithmetic operations
Type* get_common_type(Type* t1, Type* t2) {
    if (!t1 || !t2) return NULL;
    
    // If types are equal, return either one
    if (types_equal(t1, t2)) return t1;
    
    // Float promotion
    if (t1->base_type == TYPE_FLOAT || t2->base_type == TYPE_FLOAT) {
        return create_type(TYPE_FLOAT);
    }
    
    // Integer promotion
    if (t1->base_type == TYPE_INT || t2->base_type == TYPE_INT) {
        return create_type(TYPE_INT);
    }
    
    // Char promotion
    if (t1->base_type == TYPE_CHAR || t2->base_type == TYPE_CHAR) {
        return create_type(TYPE_CHAR);
    }
    
    return t1; // Default to first type
}

// Print symbol table for debugging
void print_symbol_table(SymbolTable* table) {
    if (!table) return;
    
    printf("Symbol Table:\n");
    for (int i = 0; i < SYMBOL_TABLE_SIZE; i++) {
        Symbol* symbol = table->buckets[i];
        while (symbol) {
            printf("  %s: ", symbol->name);
            switch (symbol->symbol_type) {
                case SYMBOL_VARIABLE: printf("VARIABLE"); break;
                case SYMBOL_FUNCTION: printf("FUNCTION"); break;
                case SYMBOL_STRUCT: printf("STRUCT"); break;
                case SYMBOL_ENUM: printf("ENUM"); break;
                case SYMBOL_TYPEDEF: printf("TYPEDEF"); break;
            }
            printf("\n");
            symbol = symbol->next;
        }
    }
}
