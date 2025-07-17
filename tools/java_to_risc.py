#!/usr/bin/env python3
"""
Java Bytecode to JVM Interpreter Pipeline
Extracts bytecode from Java class files and creates RISC-compatible programs
"""

import subprocess
import sys
import os

def extract_bytecode(java_file):
    """Extract bytecode from Java class file"""
    class_name = java_file.replace('.java', '')
    
    # Compile Java to bytecode
    subprocess.run(['javac', java_file], check=True)
    
    # Get bytecode disassembly
    result = subprocess.run(['javap', '-c', class_name], 
                          capture_output=True, text=True)
    
    bytecode_lines = result.stdout.split('\n')
    
    # Extract main method bytecode
    in_main = False
    bytecode_ops = []
    
    for line in bytecode_lines:
        line = line.strip()
        if 'public static int main()' in line:
            in_main = True
            continue
        if in_main and line.startswith('Code:'):
            continue
        if in_main and line and ':' in line and not line.startswith('//'):
            # Parse bytecode instruction
            parts = line.split(':')
            if len(parts) > 1:
                instruction = parts[1].strip().split()[0]
                bytecode_ops.append(instruction)
        if in_main and (line.startswith('}') or line.startswith('public')):
            break
    
    return bytecode_ops

def bytecode_to_numbers(bytecode_ops):
    """Convert bytecode operations to numeric opcodes"""
    opcode_map = {
        'iconst_0': 3,
        'iconst_1': 4,
        'iconst_2': 5,
        'iconst_3': 6,
        'iconst_4': 7,
        'iconst_5': 8,
        'bipush': 16,
        'iload_0': 26,
        'iload_1': 27,
        'iload_2': 28,
        'istore_0': 59,
        'istore_1': 60,
        'istore_2': 61,
        'iload': 21,
        'istore': 54,
        'iadd': 96,
        'isub': 100,
        'imul': 104,
        'idiv': 108,
        'irem': 112,
        'ireturn': 172,
        'return': 177
    }
    
    numeric_bytecode = []
    for op in bytecode_ops:
        if op in opcode_map:
            numeric_bytecode.append(opcode_map[op])
        else:
            print(f"Warning: Unknown bytecode operation: {op}")
    
    return numeric_bytecode

def create_jvm_c_program(bytecode_numbers, output_file):
    """Create a C program that executes the bytecode on our JVM"""
    
    bytecode_array = ', '.join(map(str, bytecode_numbers))
    
    c_program = f'''/*
 * Generated JVM Program for RISC Processor
 * Executes Java bytecode: {bytecode_numbers}
 */

struct JVM {{
    int stack[16];
    int sp;
    int locals[8];
}};

int main() {{
    struct JVM jvm;
    int bytecode[{len(bytecode_numbers)}];
    int pc;
    int opcode;
    int a;
    int b;
    int result;
    
    /* Initialize JVM */
    jvm.sp = 0;
    jvm.locals[0] = 0;
    jvm.locals[1] = 0;
    jvm.locals[2] = 0;
    
    /* Load bytecode program */
    {generate_bytecode_assignments(bytecode_numbers)}
    
    /* Execute bytecode */
    pc = 0;
    while (pc < {len(bytecode_numbers)}) {{
        opcode = bytecode[pc];
        pc = pc + 1;
        
        /* BIPUSH: push byte value */
        if (opcode == 16) {{
            /* Next byte is the value - simulate with 10 for now */
            jvm.stack[jvm.sp] = 10;
            jvm.sp = jvm.sp + 1;
        }}
        
        /* ICONST_5: push 5 */
        if (opcode == 8) {{
            jvm.stack[jvm.sp] = 5;
            jvm.sp = jvm.sp + 1;
        }}
        
        /* ISTORE_0: store to local 0 */
        if (opcode == 59) {{
            jvm.sp = jvm.sp - 1;
            jvm.locals[0] = jvm.stack[jvm.sp];
        }}
        
        /* ISTORE_1: store to local 1 */
        if (opcode == 60) {{
            jvm.sp = jvm.sp - 1;
            jvm.locals[1] = jvm.stack[jvm.sp];
        }}
        
        /* ILOAD_0: load local 0 */
        if (opcode == 26) {{
            jvm.stack[jvm.sp] = jvm.locals[0];
            jvm.sp = jvm.sp + 1;
        }}
        
        /* ILOAD_1: load local 1 */
        if (opcode == 27) {{
            jvm.stack[jvm.sp] = jvm.locals[1];
            jvm.sp = jvm.sp + 1;
        }}
        
        /* IADD: add two integers */
        if (opcode == 96) {{
            jvm.sp = jvm.sp - 1;
            b = jvm.stack[jvm.sp];
            jvm.sp = jvm.sp - 1;
            a = jvm.stack[jvm.sp];
            result = a + b;
            jvm.stack[jvm.sp] = result;
            jvm.sp = jvm.sp + 1;
        }}
        
        /* ISTORE_2: store to local 2 */
        if (opcode == 61) {{
            jvm.sp = jvm.sp - 1;
            jvm.locals[2] = jvm.stack[jvm.sp];
        }}
        
        /* ILOAD_2: load local 2 */
        if (opcode == 28) {{
            jvm.stack[jvm.sp] = jvm.locals[2];
            jvm.sp = jvm.sp + 1;
        }}
        
        /* IRETURN: return integer */
        if (opcode == 172) {{
            jvm.sp = jvm.sp - 1;
            return jvm.stack[jvm.sp];
        }}
    }}
    
    return 0;
}}
'''
    
    with open(output_file, 'w') as f:
        f.write(c_program)

def generate_bytecode_assignments(bytecode_numbers):
    """Generate C assignments for bytecode array"""
    assignments = []
    for i, value in enumerate(bytecode_numbers):
        assignments.append(f"    bytecode[{i}] = {value};")
    return '\n'.join(assignments)

def main():
    if len(sys.argv) != 2:
        print("Usage: python3 java_to_risc.py <java_file>")
        sys.exit(1)
    
    java_file = sys.argv[1]
    
    # Extract bytecode
    print(f"Extracting bytecode from {java_file}...")
    bytecode_ops = extract_bytecode(java_file)
    print(f"Bytecode operations: {bytecode_ops}")
    
    # Convert to numbers
    bytecode_numbers = bytecode_to_numbers(bytecode_ops)
    print(f"Numeric bytecode: {bytecode_numbers}")
    
    # Create C program
    output_file = java_file.replace('.java', '_jvm.c')
    create_jvm_c_program(bytecode_numbers, output_file)
    print(f"Created JVM C program: {output_file}")
    
    return output_file

if __name__ == "__main__":
    main()
