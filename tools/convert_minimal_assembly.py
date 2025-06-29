#!/usr/bin/env python3

"""
Minimal Assembly Converter - Strips runtime functions and converts to assembler format
"""

import sys

def convert_minimal_assembly(input_file, output_file):
    """Convert C compiler output to minimal assembler-compatible format"""
    
    try:
        with open(input_file, 'r') as f:
            lines = f.readlines()
        
        converted_lines = []
        skip_until_main = True
        
        # Add required assembler directives
        converted_lines.append(".org 0x8000\n")
        converted_lines.append("\n")
        converted_lines.append("; Initialize stack pointer\n")
        converted_lines.append("LOADI R30, #0x000F0000\n")
        converted_lines.append("; Initialize heap pointer  \n")
        converted_lines.append("LOADI R29, #0x20000\n")
        converted_lines.append("\n")
        
        for line in lines:
            line = line.strip()
            
            # Skip until we find main function
            if 'main:' in line:
                skip_until_main = False
                converted_lines.append("; Function: main\n")
                converted_lines.append("main:\n")
                continue
                
            if skip_until_main:
                continue
                
            # Skip empty lines and comments
            if not line or line.startswith(';') or line.startswith('//'):
                continue
                
            # Convert basic instructions to assembler format
            if 'mov r' in line and '#' in line:
                # Extract immediate value
                parts = line.split('#')
                if len(parts) == 2:
                    value = parts[1].strip()
                    reg_part = parts[0].split()
                    if len(reg_part) >= 2:
                        reg = reg_part[1].rstrip(',').upper()
                        converted_lines.append(f"LOADI {reg}, #{value}\n")
                        continue
            
            if 'add' in line and 'r' in line:
                parts = line.split()
                if len(parts) >= 4:
                    reg1 = parts[1].rstrip(',').upper()
                    reg2 = parts[2].rstrip(',').upper()
                    reg3 = parts[3].rstrip(',').upper()
                    converted_lines.append(f"ADD {reg1}, {reg2}, {reg3}\n")
                    continue
                    
            if 'sub' in line and 'r' in line:
                parts = line.split()
                if len(parts) >= 4:
                    reg1 = parts[1].rstrip(',').upper()
                    reg2 = parts[2].rstrip(',').upper()
                    reg3 = parts[3].rstrip(',').upper()
                    converted_lines.append(f"SUB {reg1}, {reg2}, {reg3}\n")
                    continue
                    
            if 'mov r0, r' in line:
                parts = line.split()
                if len(parts) >= 3:
                    reg = parts[2].upper()
                    converted_lines.append(f"MOVE R0, {reg}\n")
                    continue
                    
            if line == 'ret':
                converted_lines.append("HALT\n")
                continue
                
            # Skip other complex instructions
            
        # Add final halt
        converted_lines.append("HALT\n")
        converted_lines.append("\n")
        
        # Write converted assembly
        with open(output_file, 'w') as f:
            f.writelines(converted_lines)
            
        print(f"Minimal assembly converted: {input_file} -> {output_file}")
        return True
        
    except Exception as e:
        print(f"Error converting assembly: {e}")
        return False

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python3 convert_minimal_assembly.py <input.s> <output.asm>")
        sys.exit(1)
    
    input_file = sys.argv[1]
    output_file = sys.argv[2]
    
    if convert_minimal_assembly(input_file, output_file):
        sys.exit(0)
    else:
        sys.exit(1)
