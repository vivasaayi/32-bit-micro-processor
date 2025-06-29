/*
 * AST Node Definitions
 * Defines all abstract syntax tree node types
 */

#ifndef AST_H
#define AST_H

#include <stddef.h>
#include "lexer.h" // For TokenType

// Forward declarations
typedef struct AstNode AstNode;
typedef struct Type Type;

// AST Node Types
typedef enum {
    // Literals
    AST_INT_LITERAL,
    AST_FLOAT_LITERAL,
    AST_CHAR_LITERAL,
    AST_STRING_LITERAL,
    AST_BOOL_LITERAL,
    AST_ARRAY_INITIALIZER,
    
    // Identifiers
    AST_IDENTIFIER,
    
    // Binary Operations
    AST_BINARY_OP,
    
    // Unary Operations
    AST_UNARY_OP,
    
    // Ternary Operations
    AST_TERNARY_OP,
    
    // Assignments
    AST_ASSIGNMENT,
    
    // Function calls
    AST_FUNCTION_CALL,
    
    // Member access
    AST_MEMBER_ACCESS,
    AST_POINTER_ACCESS,
    
    // Array access
    AST_ARRAY_ACCESS,
    
    // Statements
    AST_COMPOUND_STMT,
    AST_IF_STMT,
    AST_WHILE_STMT,
    AST_FOR_STMT,
    AST_SWITCH_STMT,
    AST_CASE_STMT,
    AST_DEFAULT_STMT,
    AST_RETURN_STMT,
    AST_BREAK_STMT,
    AST_CONTINUE_STMT,
    AST_EXPRESSION_STMT,
    
    // Declarations
    AST_VARIABLE_DECL,
    AST_FUNCTION_DECL,
    AST_STRUCT_DECL,
    AST_ENUM_DECL,
    AST_TYPEDEF_DECL,
    
    // Parameter and argument lists
    AST_PARAMETER_LIST,
    AST_ARGUMENT_LIST,
    AST_PARAMETER,
    
    // Program
    AST_PROGRAM
} AstNodeType;

// Binary operators
typedef enum {
    BINOP_ADD, BINOP_SUB, BINOP_MUL, BINOP_DIV, BINOP_MOD,
    BINOP_EQ, BINOP_NE, BINOP_LT, BINOP_LE, BINOP_GT, BINOP_GE,
    BINOP_AND, BINOP_OR,
    BINOP_BITAND, BINOP_BITOR, BINOP_BITXOR,
    BINOP_SHL, BINOP_SHR
} BinaryOp;

// Unary operators
typedef enum {
    UNOP_NOT, UNOP_NEG, UNOP_BITNOT,
    UNOP_ADDR, UNOP_DEREF,
    UNOP_PREINC, UNOP_PREDEC,
    UNOP_POSTINC, UNOP_POSTDEC
} UnaryOp;

// Data types
typedef enum {
    TYPE_VOID, TYPE_INT, TYPE_CHAR, TYPE_FLOAT, TYPE_DOUBLE, TYPE_BOOL,
    TYPE_POINTER, TYPE_ARRAY, TYPE_STRUCT, TYPE_ENUM, TYPE_FUNCTION
} TypeKind;

// Type information
struct Type {
    TypeKind base_type;
    char* name;                // For struct/enum names
    Type* element_type;        // For pointers, arrays
    Type* return_type;         // For functions
    int array_size;            // For arrays
    union {
        struct {
            Type* base_type;  // For pointers and arrays
            int size;         // For arrays
        } derived;
        struct {
            char* name;
            AstNode* declaration;
        } user_defined;
        struct {
            Type* return_type;
            Type** param_types;
            int param_count;
        } function;
    };
};

// AST Node structure
struct AstNode {
    AstNodeType type;
    Type* data_type;  // Type information after type checking
    
    // Child nodes
    AstNode** children;
    int child_count;
    int child_capacity;
    
    union {
        // Literals
        struct {
            int value;
        } int_literal;
        
        struct {
            float value;
        } float_literal;
        
        struct {
            char value;
        } char_literal;
        
        struct {
            char* value;
        } string_literal;
        
        struct {
            int value; // 0 for false, 1 for true
        } bool_literal;
        
        // Identifier
        struct {
            char* name;
        } identifier;
        
        // Binary operation
        struct {
            TokenType operator;
        } binary_op;
        
        // Unary operation
        struct {
            TokenType operator;
        } unary_op;
        
        // Assignment
        struct {
            TokenType operator;
        } assignment;
        
        // Member access
        struct {
            char* member;
        } member_access;
        
        // Pointer access
        struct {
            char* member;
        } pointer_access;
        
        // Declarations
        struct {
            char* name;
            Type* return_type;
        } function_decl;
        
        struct {
            char* name;
            Type* type;
        } variable_decl;
        
        struct {
            char* name;
        } struct_decl;
        
        struct {
            char* name;
        } enum_decl;
        
        struct {
            char* name;
            Type* type;
        } typedef_decl;
        
        struct {
            char* name;
            Type* type;
        } parameter;
        
        // Switch statements
        struct {
            AstNode* expression;  // Expression to switch on
        } switch_stmt;
        
        struct {
            AstNode* value;      // Case value
        } case_stmt;
        
        struct {
            // Default case has no additional data
        } default_stmt;
    } data;
};

// Function prototypes
AstNode* create_ast_node(AstNodeType type);
void free_ast(AstNode* node);
Type* create_type(TypeKind kind);
void free_type(Type* type);
void print_ast(AstNode* node, int indent);

// Node creation functions
AstNode* create_int_literal(int value);
AstNode* create_float_literal(float value);
AstNode* create_char_literal(char value);
AstNode* create_string_literal(const char* value);
AstNode* create_bool_literal(int value);
AstNode* create_array_initializer(void);
AstNode* create_identifier(const char* name);

AstNode* create_binary_op(AstNode* left, AstNode* right, TokenType operator);
AstNode* create_unary_op(AstNode* operand, TokenType operator);
AstNode* create_ternary_op(AstNode* condition, AstNode* true_expr, AstNode* false_expr);
AstNode* create_postfix_op(AstNode* operand, TokenType operator);
AstNode* create_assignment(AstNode* left, AstNode* right, TokenType operator);
AstNode* create_function_call(AstNode* function, AstNode* args);
AstNode* create_array_access(AstNode* array, AstNode* index);
AstNode* create_member_access(AstNode* object, const char* member);
AstNode* create_pointer_access(AstNode* object, const char* member);

AstNode* create_compound_stmt(void);
AstNode* create_if_stmt(AstNode* condition, AstNode* then_stmt, AstNode* else_stmt);
AstNode* create_while_stmt(AstNode* condition, AstNode* body);
AstNode* create_for_stmt(AstNode* init, AstNode* condition, AstNode* increment, AstNode* body);
AstNode* create_switch_stmt(AstNode* expression, AstNode* body);
AstNode* create_case_stmt(AstNode* value, AstNode* statements);
AstNode* create_default_stmt(AstNode* statements);
AstNode* create_return_stmt(AstNode* value);
AstNode* create_break_stmt(void);
AstNode* create_continue_stmt(void);
AstNode* create_expression_stmt(AstNode* expression);

AstNode* create_function_decl(const char* name, Type* return_type, AstNode* params, AstNode* body);
AstNode* create_variable_decl(const char* name, Type* type, AstNode* initializer);
AstNode* create_struct_decl(const char* name, AstNode* fields);
AstNode* create_enum_decl(const char* name, AstNode* values);
AstNode* create_typedef_decl(const char* name, Type* type);

AstNode* create_parameter_list(void);
AstNode* create_argument_list(void);
AstNode* create_parameter(const char* name, Type* type);

void add_child(AstNode* parent, AstNode* child);

// Type creation helpers
Type* create_pointer_type(Type* base_type);
Type* create_array_type(Type* element_type, int size);
Type* create_function_type(Type* return_type);
Type* create_struct_type(const char* name);
Type* create_enum_type(const char* name);
Type* create_custom_type(const char* name);

#endif
