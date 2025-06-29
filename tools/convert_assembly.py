#!/usr/bin/env python3

"""
Assembly Syntax Converter
Converts C compiler output to assembler-compatible format
"""

import sys
import re

def convert_assembly(input_file, output_file):
    """Convert assembly syntax from C compiler to assembler format"""
    
    # Instruction mapping from C compiler output to assembler input
    instruction_map = {
        'load': 'LOAD',
        'loadi': 'LOADI', 
        'store': 'STORE',
        'mov': 'MOVE',
        'move': 'MOVE',
        'add': 'ADD',
        'addi': 'ADDI',
        'sub': 'SUB',
        'subi': 'SUBI',
        'mul': 'MUL',
        'div': 'DIV',
        'mod': 'MOD',
        'and': 'AND',
        'or': 'OR',
        'xor': 'XOR',
        'not': 'NOT',
        'shl': 'SHL',
        'shr': 'SHR',
        'cmp': 'CMP',
        'jmp': 'JMP',
        'jz': 'JZ',
        'jnz': 'JNZ',
        'je': 'JZ',
        'jne': 'JNZ',
        'call': 'CALL',
        'ret': 'RET',
        'halt': 'HALT',
        'nop': 'NOP',
        'out': 'OUT'
    }
    
    # Register mapping
    register_map = {
        'r0': 'R0', 'r1': 'R1', 'r2': 'R2', 'r3': 'R3',
        'r4': 'R4', 'r5': 'R5', 'r6': 'R6', 'r7': 'R7',
        'r8': 'R8', 'r9': 'R9', 'r10': 'R10', 'r11': 'R11',
        'r12': 'R12', 'r13': 'R13', 'r14': 'R14', 'r15': 'R15',
        'r16': 'R16', 'r17': 'R17', 'r18': 'R18', 'r19': 'R19',
        'r20': 'R20', 'r21': 'R21', 'r22': 'R22', 'r23': 'R23',
        'r24': 'R24', 'r25': 'R25', 'r26': 'R26', 'r27': 'R27',
        'r28': 'R28', 'r29': 'R29', 'r30': 'R30', 'r31': 'R31',
        'fp': 'R29', 'sp': 'R30'
    }
    
    try:
        with open(input_file, 'r') as f:
            lines = f.readlines()
        
        converted_lines = []
        
        for line_num, line in enumerate(lines, 1):
            original_line = line
            line = line.strip()
            
            # Skip empty lines and comments
            if not line or line.startswith(';') or line.startswith('//'):
                converted_lines.append(original_line)
                continue
                
            # Handle labels (lines ending with :)
            if line.endswith(':'):
                converted_lines.append(original_line)
                continue
                
            # Handle data directives
            if line.startswith('.') or line.startswith('heap_ptr:') or 'word' in line:
                converted_lines.append(original_line)
                continue
                
            # Convert instructions
            parts = line.split()
            if parts:
                instruction = parts[0].lower()
                
                if instruction in instruction_map:
                    # Convert instruction to uppercase
                    parts[0] = instruction_map[instruction]
                    
                    # Convert registers to uppercase
                    for i in range(1, len(parts)):
                        part = parts[i].rstrip(',')
                        if part.lower() in register_map:
                            parts[i] = register_map[part.lower()] + (',' if parts[i].endswith(',') else '')
                        elif part.startswith('[') and part.endswith(']'):
                            # Handle memory references like [r1]
                            inner = part[1:-1].lower()
                            if inner in register_map:
                                parts[i] = '[' + register_map[inner] + ']'
                    
                    # Handle immediate values - ensure they start with #
                    for i in range(1, len(parts)):
                        part = parts[i].rstrip(',')
                        if part.isdigit() or (part.startswith('-') and part[1:].isdigit()):
                            if not part.startswith('#'):
                                parts[i] = '#' + part + (',' if parts[i].endswith(',') else '')
                    
                    converted_line = '    ' + ' '.join(parts) + '\n'
                    converted_lines.append(converted_line)
                else:
                    # Unknown instruction, keep as is but add warning
                    converted_lines.append(f"    ; WARNING: Unknown instruction: {instruction}\n")
                    converted_lines.append(original_line)
            else:
                converted_lines.append(original_line)
        
        # Write converted assembly
        with open(output_file, 'w') as f:
            f.writelines(converted_lines)
            
        print(f"Assembly converted successfully: {input_file} -> {output_file}")
        return True
        
    except Exception as e:
        print(f"Error converting assembly: {e}")
        return False

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python3 convert_assembly.py <input.s> <output.asm>")
        sys.exit(1)
    
    input_file = sys.argv[1]
    output_file = sys.argv[2]
    
    if convert_assembly(input_file, output_file):
        sys.exit(0)
    else:
        sys.exit(1)
