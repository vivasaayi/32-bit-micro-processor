/* 
 * Simple C Compiler - Main Entry Point
 * Compiles C code to custom RISC-style assembly
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "lexer.h"
#include "parser.h"
#include "ast.h"
#include "type_checker.h"
#include "codegen.h"

void usage(const char* prog) {
    printf("Usage: %s <input.c> [-o output.s]\n", prog);
    printf("  Compiles C source to custom assembly\n");
}

int main(int argc, char** argv) {
    if (argc < 2) {
        usage(argv[0]);
        return 1;
    }
    
    const char* input_file = argv[1];
    const char* output_file = "output.s";
    
    // Parse command line arguments
    for (int i = 2; i < argc; i++) {
        if (strcmp(argv[i], "-o") == 0 && i + 1 < argc) {
            output_file = argv[i + 1];
            i++; // Skip next argument
        }
    }
    
    // Read input file
    FILE* file = fopen(input_file, "r");
    if (!file) {
        fprintf(stderr, "Error: Cannot open file '%s'\n", input_file);
        return 1;
    }
    
    // Get file size
    fseek(file, 0, SEEK_END);
    long file_size = ftell(file);
    fseek(file, 0, SEEK_SET);
    
    // Read entire file
    char* source = malloc(file_size + 1);
    fread(source, 1, file_size, file);
    source[file_size] = '\0';
    fclose(file);
    
    printf("Compiling '%s' to '%s'...\n", input_file, output_file);
    
    // 1. Lexical Analysis
    TokenList* tokens = tokenize(source);
    if (!tokens) {
        fprintf(stderr, "Lexical analysis failed\n");
        free(source);
        return 1;
    }
    printf("Lexical analysis: %d tokens\n", tokens->count);
    
    // 2. Parsing
    AstNode* ast = parse(tokens);
    if (!ast) {
        fprintf(stderr, "Parsing failed\n");
        free_tokens(tokens);
        free(source);
        return 1;
    }
    printf("Parsing: AST generated\n");
    
    // 3. Type Checking
    SymbolTable* symbols = create_symbol_table();
    if (!type_check(ast, symbols)) {
        fprintf(stderr, "Type checking failed\n");
        free_ast(ast);
        free_tokens(tokens);
        free_symbol_table(symbols);
        free(source);
        return 1;
    }
    printf("Type checking: passed\n");
    
    // 4. Code Generation
    FILE* output = fopen(output_file, "w");
    if (!output) {
        fprintf(stderr, "Error: Cannot create output file '%s'\n", output_file);
        free_ast(ast);
        free_tokens(tokens);
        free_symbol_table(symbols);
        free(source);
        return 1;
    }
    
    if (!generate_code(ast, symbols, output)) {
        fprintf(stderr, "Code generation failed\n");
        fclose(output);
        free_ast(ast);
        free_tokens(tokens);
        free_symbol_table(symbols);
        free(source);
        return 1;
    }
    
    fclose(output);
    printf("Code generation: completed successfully\n");
    printf("Assembly written to '%s'\n", output_file);
    
    // Cleanup
    free_ast(ast);
    free_tokens(tokens);
    free_symbol_table(symbols);
    free(source);
    
    return 0;
}
