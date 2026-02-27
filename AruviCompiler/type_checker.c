/*
 * Type Checker Implementation
 */

#include "type_checker.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// Hash function for symbol table
unsigned int hash_string(const char *str) {
  unsigned int hash = 5381;
  while (*str) {
    hash = ((hash << 5) + hash) + *str++;
  }
  return hash % SYMBOL_TABLE_SIZE;
}

// Create a new symbol table
SymbolTable *create_symbol_table(void) {
  SymbolTable *table = malloc(sizeof(SymbolTable));
  memset(table->buckets, 0, sizeof(table->buckets));
  table->parent = NULL;
  return table;
}

// Free symbol table and all symbols
void free_symbol_table(SymbolTable *table) {
  if (!table)
    return;

  for (int i = 0; i < SYMBOL_TABLE_SIZE; i++) {
    Symbol *symbol = table->buckets[i];
    while (symbol) {
      Symbol *next = symbol->next;
      free(symbol->name);
      // Don't free type here - it's owned by AST
      free(symbol);
      symbol = next;
    }
  }

  free(table);
}

// Push a new scope (create child symbol table)
SymbolTable *push_scope(SymbolTable *current) {
  SymbolTable *new_scope = create_symbol_table();
  new_scope->parent = current;
  return new_scope;
}

// Pop scope (return to parent)
SymbolTable *pop_scope(SymbolTable *current) {
  if (!current)
    return NULL;
  SymbolTable *parent = current->parent;
  free_symbol_table(current);
  return parent;
}

// Lookup symbol in current scope and parent scopes
Symbol *lookup_symbol(SymbolTable *table, const char *name) {
  while (table) {
    Symbol *symbol = lookup_symbol_local(table, name);
    if (symbol)
      return symbol;
    table = table->parent;
  }
  return NULL;
}

// Lookup symbol only in current scope
Symbol *lookup_symbol_local(SymbolTable *table, const char *name) {
  if (!table || !name)
    return NULL;

  unsigned int hash = hash_string(name);
  Symbol *symbol = table->buckets[hash];

  while (symbol) {
    if (strcmp(symbol->name, name) == 0) {
      return symbol;
    }
    symbol = symbol->next;
  }

  return NULL;
}

// Add symbol to current scope
int add_symbol(SymbolTable *table, const char *name, SymbolType symbol_type,
               Type *type, AstNode *declaration) {
  if (!table || !name)
    return 0;

  // Check if symbol already exists in current scope
  if (lookup_symbol_local(table, name)) {
    printf("Error: Symbol '%s' already declared in current scope\n", name);
    return 0;
  }

  // Create new symbol
  Symbol *symbol = malloc(sizeof(Symbol));
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
int type_check(AstNode *ast, SymbolTable *symbols) {
  if (!ast || !symbols)
    return 0;

  return type_check_node(ast, symbols);
}

// Type check a single node
int type_check_node(AstNode *node, SymbolTable *symbols) {
  if (!node)
    return 1;

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
  case AST_BOOL_LITERAL:
  case AST_ARRAY_INITIALIZER:
  case AST_IDENTIFIER: {
    Type *result_type = NULL;
    int success = type_check_expression(node, symbols, &result_type);
    if (success) {
      node->data_type = result_type;
    }
    return success;
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
int type_check_expression(AstNode *expr, SymbolTable *symbols,
                          Type **result_type) {
  if (!expr) {
    *result_type = NULL;
    return 0;
  }

  int success = 0;
  Type *local_result = NULL;

  switch (expr->type) {
  case AST_INT_LITERAL:
    local_result = create_type(TYPE_INT);
    success = 1;
    break;

  case AST_FLOAT_LITERAL:
    local_result = create_type(TYPE_FLOAT);
    success = 1;
    break;

  case AST_CHAR_LITERAL:
    local_result = create_type(TYPE_CHAR);
    success = 1;
    break;

  case AST_STRING_LITERAL:
    local_result = create_pointer_type(create_type(TYPE_CHAR));
    success = 1;
    break;

  case AST_BOOL_LITERAL:
    local_result = create_type(TYPE_BOOL);
    success = 1;
    break;

  case AST_ARRAY_INITIALIZER: {
    // Array initializer type will be determined by context
    // For now, assume it's an array of int
    Type *element_type = create_type(TYPE_INT);
    local_result = create_array_type(element_type, expr->child_count);

    success = 1;
    // Type check all elements
    for (int i = 0; i < expr->child_count; i++) {
      Type *elem_type;
      if (!type_check_expression(expr->children[i], symbols, &elem_type)) {
        local_result = NULL;
        success = 0;
        break;
      }
      // TODO: Check that all elements are compatible with element_type
    }
    break;
  }

  case AST_IDENTIFIER: {
    Symbol *symbol = lookup_symbol(symbols, expr->data.identifier.name);
    if (!symbol) {
      printf("Error: Undefined identifier '%s'\n", expr->data.identifier.name);
      local_result = NULL;
      success = 0;
    } else {
      local_result = symbol->type;
      success = 1;
    }
    break;
  }

  case AST_BINARY_OP: {
    Type *left_type, *right_type;
    if (!type_check_expression(expr->children[0], symbols, &left_type) ||
        !type_check_expression(expr->children[1], symbols, &right_type)) {
      local_result = NULL;
      success = 0;
      break;
    }

    success = 1;
    // Check type compatibility based on operator
    switch (expr->data.binary_op.op) {
    case TOK_PLUS:
    case TOK_MINUS:
      // Handle pointer arithmetic: ptr + int, ptr - int, ptr - ptr
      if (left_type->base_type == TYPE_POINTER &&
          right_type->base_type == TYPE_INT) {
        local_result = left_type; // Result is same pointer type
      } else if (left_type->base_type == TYPE_INT &&
                 right_type->base_type == TYPE_POINTER) {
        if (expr->data.binary_op.op == TOK_PLUS) {
          local_result = right_type; // Result is pointer type
        } else {
          printf("Error: Cannot subtract pointer from integer\n");
          local_result = NULL;
          success = 0;
        }
      } else if (left_type->base_type == TYPE_POINTER &&
                 right_type->base_type == TYPE_POINTER) {
        if (expr->data.binary_op.op == TOK_MINUS) {
          local_result = create_type(TYPE_INT); // Result is integer (offset)
        } else {
          printf("Error: Cannot add two pointers\n");
          local_result = NULL;
          success = 0;
        }
      } else {
        if (!types_compatible(left_type, right_type)) {
          printf("Error: Incompatible types in arithmetic operation\n");
          local_result = NULL;
          success = 0;
        } else {
          local_result = get_common_type(left_type, right_type);
        }
      }
      break;

    case TOK_MULTIPLY:
    case TOK_DIVIDE:
    case TOK_MODULO:
      if (!types_compatible(left_type, right_type)) {
        printf("Error: Incompatible types in arithmetic operation\n");
        local_result = NULL;
        success = 0;
      } else {
        local_result = get_common_type(left_type, right_type);
      }
      break;

    case TOK_EQ:
    case TOK_NE:
    case TOK_LT:
    case TOK_LE:
    case TOK_GT:
    case TOK_GE:
      if (!types_compatible(left_type, right_type)) {
        printf("Error: Incompatible types in comparison\n");
        local_result = NULL;
        success = 0;
      } else {
        local_result = create_type(TYPE_INT); // Boolean result
      }
      break;

    case TOK_AND:
    case TOK_OR:
      local_result = create_type(TYPE_INT); // Boolean result
      break;

    case TOK_BITAND:
    case TOK_BITOR:
    case TOK_BITXOR:
    case TOK_SHL:
    case TOK_SHR:
      if (left_type->base_type != TYPE_INT ||
          right_type->base_type != TYPE_INT) {
        printf("Error: Bitwise operations require integer types\n");
        local_result = NULL;
        success = 0;
      } else {
        local_result = create_type(TYPE_INT);
      }
      break;

    default:
      printf("Error: Unknown binary operator\n");
      local_result = NULL;
      success = 0;
    }
    break;
  }

  case AST_TERNARY_OP: {
    Type *condition_type, *true_type, *false_type;

    if (!type_check_expression(expr->children[0], symbols, &condition_type) ||
        !type_check_expression(expr->children[1], symbols, &true_type) ||
        !type_check_expression(expr->children[2], symbols, &false_type)) {
      local_result = NULL;
      success = 0;
      break;
    }

    if (condition_type->base_type != TYPE_INT &&
        condition_type->base_type != TYPE_FLOAT &&
        condition_type->base_type != TYPE_CHAR &&
        condition_type->base_type != TYPE_BOOL) {
      printf("Error: Ternary condition must be numeric or boolean type\n");
      local_result = NULL;
      success = 0;
    } else if (!types_compatible(true_type, false_type)) {
      printf("Error: Incompatible types in ternary true/false expressions\n");
      local_result = NULL;
      success = 0;
    } else {
      local_result = get_common_type(true_type, false_type);
      success = 1;
    }
    break;
  }

  case AST_UNARY_OP:
  case AST_POSTFIX_OP: {
    Type *operand_type;
    if (!type_check_expression(expr->children[0], symbols, &operand_type)) {
      local_result = NULL;
      success = 0;
      break;
    }

    success = 1;
    switch (expr->data.unary_op.op) {
    case TOK_MINUS:
    case TOK_PLUS:
      if (operand_type->base_type != TYPE_INT &&
          operand_type->base_type != TYPE_FLOAT) {
        printf("Error: Unary +/- requires numeric type\n");
        local_result = NULL;
        success = 0;
      } else {
        local_result = operand_type;
      }
      break;

    case TOK_NOT:
      local_result = create_type(TYPE_INT);
      break;

    case TOK_BITNOT:
      if (operand_type->base_type != TYPE_INT) {
        printf("Error: Bitwise NOT requires integer type\n");
        local_result = NULL;
        success = 0;
      } else {
        local_result = create_type(TYPE_INT);
      }
      break;

    case TOK_MULTIPLY: // Dereference (*ptr)
      if (operand_type->base_type != TYPE_POINTER &&
          operand_type->base_type != TYPE_ARRAY) {
        printf("Error: Dereference requires pointer or array type\n");
        local_result = NULL;
        success = 0;
      } else {
        local_result = operand_type->element_type;
      }
      break;

    case TOK_BITAND: // Address-of (&var)
      local_result = create_pointer_type(operand_type);
      break;

    case TOK_INCREMENT:
    case TOK_DECREMENT:
      if (operand_type->base_type != TYPE_INT &&
          operand_type->base_type != TYPE_FLOAT &&
          operand_type->base_type != TYPE_CHAR &&
          operand_type->base_type != TYPE_POINTER) {
        printf("Error: Increment/decrement requires numeric or pointer type\n");
        local_result = NULL;
        success = 0;
      } else {
        local_result = operand_type;
      }
      break;

    default:
      printf("Error: Unknown unary operator\n");
      local_result = NULL;
      success = 0;
    }
    break;
  }

  case AST_ASSIGNMENT: {
    Type *left_type, *right_type;
    if (!type_check_expression(expr->children[0], symbols, &left_type) ||
        !type_check_expression(expr->children[1], symbols, &right_type)) {
      local_result = NULL;
      success = 0;
      break;
    }

    success = 1;
    TokenType op = expr->data.assignment.op;
    if (op == TOK_ASSIGN) {
      if (!types_compatible(left_type, right_type)) {
        printf("Error: Incompatible types in assignment\n");
        local_result = NULL;
        success = 0;
      } else {
        local_result = left_type;
      }
    } else {
      if (op == TOK_PLUS_ASSIGN || op == TOK_MINUS_ASSIGN ||
          op == TOK_MUL_ASSIGN || op == TOK_DIV_ASSIGN ||
          op == TOK_MOD_ASSIGN) {
        if ((left_type->base_type != TYPE_INT &&
             left_type->base_type != TYPE_FLOAT &&
             left_type->base_type != TYPE_CHAR) ||
            (right_type->base_type != TYPE_INT &&
             right_type->base_type != TYPE_FLOAT &&
             right_type->base_type != TYPE_CHAR)) {
          printf("Error: Arithmetic compound assignment requires numeric "
                 "types\n");
          local_result = NULL;
          success = 0;
        }
      } else if (op == TOK_AND_ASSIGN || op == TOK_OR_ASSIGN ||
                 op == TOK_XOR_ASSIGN || op == TOK_SHL_ASSIGN ||
                 op == TOK_SHR_ASSIGN) {
        if ((left_type->base_type != TYPE_INT &&
             left_type->base_type != TYPE_CHAR &&
             left_type->base_type != TYPE_BOOL) ||
            (right_type->base_type != TYPE_INT &&
             right_type->base_type != TYPE_CHAR &&
             right_type->base_type != TYPE_BOOL)) {
          printf("Error: Bitwise compound assignment requires integer or "
                 "boolean types\n");
          local_result = NULL;
          success = 0;
        }
      }
      if (success && !types_compatible(left_type, right_type)) {
        printf("Error: Incompatible types in compound assignment\n");
        local_result = NULL;
        success = 0;
      } else if (success) {
        local_result = left_type;
      }
    }
    break;
  }

  case AST_MEMBER_ACCESS: {
    Type *obj_type;
    if (!type_check_expression(expr->children[0], symbols, &obj_type)) {
      local_result = NULL;
      success = 0;
      break;
    }
    local_result = create_type(TYPE_INT);
    success = 1;
    break;
  }

  case AST_POINTER_ACCESS: {
    Type *obj_type;
    if (!type_check_expression(expr->children[0], symbols, &obj_type)) {
      local_result = NULL;
      success = 0;
      break;
    }
    local_result = create_type(TYPE_INT);
    success = 1;
    break;
  }

  case AST_ARRAY_ACCESS: {
    Type *arr_type, *idx_type;
    if (!type_check_expression(expr->children[0], symbols, &arr_type) ||
        !type_check_expression(expr->children[1], symbols, &idx_type)) {
      local_result = NULL;
      success = 0;
      break;
    }
    if (arr_type->base_type != TYPE_POINTER &&
        arr_type->base_type != TYPE_ARRAY) {
      printf("Error: Array access on non-pointer/array type\n");
      local_result = NULL;
      success = 0;
    } else {
      local_result = arr_type->element_type;
      success = 1;
    }
    break;
  }

  case AST_FUNCTION_CALL: {
    Type *func_type;
    if (!type_check_expression(expr->children[0], symbols, &func_type)) {
      local_result = NULL;
      success = 0;
      break;
    }
    if (expr->children[0]->type == AST_IDENTIFIER) {
      Symbol *symbol =
          lookup_symbol(symbols, expr->children[0]->data.identifier.name);
      if (symbol && symbol->symbol_type == SYMBOL_FUNCTION) {
        local_result = symbol->type;
        success = 1;

        // Type check arguments
        if (expr->child_count > 1 && expr->children[1]) {
          AstNode *args = expr->children[1];
          for (int i = 0; i < args->child_count; i++) {
            Type *arg_type;
            if (!type_check_expression(args->children[i], symbols, &arg_type)) {
              success = 0;
              break;
            }
          }
        }
      } else {
        printf("Error: Function call on non-function type\n");
        local_result = NULL;
        success = 0;
      }
    } else {
      printf("Error: Function call on non-function type\n");
      local_result = NULL;
      success = 0;
    }
    break;
  }

  default:
    printf("Error: Unsupported expression type %d in type checking\n",
           expr->type);
    local_result = NULL;
    success = 0;
    break;
  }

  if (success) {
    expr->data_type = local_result;
    *result_type = local_result;
  } else {
    *result_type = NULL;
  }

  return success;
}

// Helper function to check if two types are compatible
int types_compatible(Type *type1, Type *type2) {
  if (!type1 || !type2)
    return 0;

  if (type1->base_type == type2->base_type) {
    return 1;
  }

  // Allow some implicit conversions
  if ((type1->base_type == TYPE_INT || type1->base_type == TYPE_CHAR) &&
      (type2->base_type == TYPE_INT || type2->base_type == TYPE_CHAR)) {
    return 1;
  }

  return 0;
}

// Helper function to get common type for arithmetic operations
Type *get_common_type(Type *type1, Type *type2) {
  if (!type1 || !type2)
    return NULL;

  // Prefer floating point over integer
  if (type1->base_type == TYPE_FLOAT || type2->base_type == TYPE_FLOAT) {
    return create_type(TYPE_FLOAT);
  }

  // Prefer int over char
  if (type1->base_type == TYPE_INT || type2->base_type == TYPE_INT) {
    return create_type(TYPE_INT);
  }

  // Default to first type
  return type1;
}

// Helper function to check declaration types and add to symbol table
int type_check_declaration(AstNode *node, SymbolTable *symbols) {
  if (!node)
    return 1;

  switch (node->type) {
  case AST_FUNCTION_DECL: {
    const char *name = node->data.function_decl.name;
    Type *ret_type = node->data.function_decl.return_type;

    // Add function to symbol table
    add_symbol(symbols, name, SYMBOL_FUNCTION, ret_type, node);

    // Create new scope for function parameters and body
    SymbolTable *func_scope = push_scope(symbols);

    // Type check parameters
    if (node->child_count > 0 && node->children[0]) {
      AstNode *params = node->children[0];
      for (int i = 0; i < params->child_count; i++) {
        AstNode *param = params->children[i];
        const char *p_name = param->data.parameter.name;
        Type *p_type = param->data.parameter.type;
        add_symbol(func_scope, p_name, SYMBOL_VARIABLE, p_type, param);
      }
    }

    // Type check body
    if (node->child_count > 1 && node->children[1]) {
      if (!type_check_node(node->children[1], func_scope)) {
        return 0;
      }
    }
    return 1;
  }

  case AST_VARIABLE_DECL: {
    const char *name = node->data.variable_decl.name;
    Type *type = node->data.variable_decl.type;

    // Type check initializer if present
    if (node->child_count > 0 && node->children[0]) {
      Type *init_type;
      if (!type_check_expression(node->children[0], symbols, &init_type)) {
        return 0;
      }
      if (!types_compatible(type, init_type)) {
        printf("Error: Incompatible types in initializer for '%s'\n", name);
        return 0;
      }
    }

    // Add to symbol table
    add_symbol(symbols, name, SYMBOL_VARIABLE, type, node);
    return 1;
  }

  default:
    return 1;
  }
}

// Helper function to check statement types
int type_check_statement(AstNode *node, SymbolTable *symbols) {
  if (!node)
    return 1;

  switch (node->type) {
  case AST_IF_STMT:
  case AST_WHILE_STMT:
  case AST_FOR_STMT:
    for (int i = 0; i < node->child_count; i++) {
      if (!type_check_node(node->children[i], symbols))
        return 0;
    }
    return 1;

  case AST_RETURN_STMT:
    if (node->child_count > 0) {
      Type *ret_type;
      return type_check_expression(node->children[0], symbols, &ret_type);
    }
    return 1;

  case AST_EXPRESSION_STMT:
    if (node->child_count > 0) {
      Type *expr_type;
      return type_check_expression(node->children[0], symbols, &expr_type);
    }
    return 1;

  default:
    return 1;
  }
}
