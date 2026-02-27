/*
 * Type Checker - Symbol table management and type validation
 */

#ifndef TYPE_CHECKER_H
#define TYPE_CHECKER_H

#include "ast.h"

// Symbol types
typedef enum {
    SYMBOL_VARIABLE,
    SYMBOL_FUNCTION,
    SYMBOL_STRUCT,
    SYMBOL_ENUM,
    SYMBOL_TYPEDEF
} SymbolType;

// Symbol table entry
typedef struct Symbol {
    char* name;
    SymbolType symbol_type;
    Type* type;
    AstNode* declaration;
    struct Symbol* next;
} Symbol;

// Symbol table (using hash table)
#define SYMBOL_TABLE_SIZE 256

typedef struct SymbolTable {
    Symbol* buckets[SYMBOL_TABLE_SIZE];
    struct SymbolTable* parent; // For nested scopes
} SymbolTable;

// Type checker functions
SymbolTable* create_symbol_table(void);
void free_symbol_table(SymbolTable* table);
SymbolTable* push_scope(SymbolTable* current);
SymbolTable* pop_scope(SymbolTable* current);

Symbol* lookup_symbol(SymbolTable* table, const char* name);
Symbol* lookup_symbol_local(SymbolTable* table, const char* name);
int add_symbol(SymbolTable* table, const char* name, SymbolType symbol_type, 
               Type* type, AstNode* declaration);

int type_check(AstNode* ast, SymbolTable* symbols);
int type_check_node(AstNode* node, SymbolTable* symbols);
int type_check_expression(AstNode* expr, SymbolTable* symbols, Type** result_type);
int type_check_statement(AstNode* stmt, SymbolTable* symbols);
int type_check_declaration(AstNode* decl, SymbolTable* symbols);

// Type compatibility checking
int types_compatible(Type* t1, Type* t2);
int types_equal(Type* t1, Type* t2);
Type* get_common_type(Type* t1, Type* t2);

// Utility functions
unsigned int hash_string(const char* str);
void print_symbol_table(SymbolTable* table);

#endif
