#!/usr/bin/env python3

import sys
import re
import os

def convert_to_riscv(content):
    lines = content.split('\n')
    converted = []
    last_cmp = None
    
    for line in lines:
        # Remove trailing comments and split
        if ';' in line:
            code, comment = line.split(';', 1)
            comment = '#' + comment
        else:
            code = line
            comment = ''
        
        code = code.strip()
        if not code:
            converted.append(comment.strip() if comment else '')
            continue
        
        # Check for cmp
        cmp_match = re.match(r'cmp\s+(\w+),\s*#?(.+)', code)
        if cmp_match:
            rs1, rs2 = cmp_match.groups()
            last_cmp = (rs1, rs2)
            code = '#' + code  # comment out cmp
        else:
            # Check for je, jne, etc.
            branch_match = re.match(r'(j\w+)\s+(\w+)', code)
            if branch_match:
                instr, label = branch_match.groups()
                if last_cmp:
                    rs1, rs2 = last_cmp
                    if instr == 'je':
                        code = f'beq {rs1}, {rs2}, {label}'
                    elif instr == 'jne':
                        code = f'bne {rs1}, {rs2}, {label}'
                    elif instr == 'jlt':
                        code = f'blt {rs1}, {rs2}, {label}'
                    # Add more if needed
                    last_cmp = None  # reset
                else:
                    # No cmp, perhaps unconditional
                    if instr == 'jmp':
                        code = f'j {label}'
            else:
                last_cmp = None  # reset if not branch
        
        # Replace instructions
        # mov rd, #imm -> addi rd, zero, imm
        code = re.sub(r'\bmov\s+(\w+),\s*#([0-9]+)', r'addi \1, zero, \2', code)
        
        # add stays
        # sub stays
        
        # load rd, [addr] -> lw rd, 0(addr) if addr is label or number
        code = re.sub(r'\bload\s+(\w+),\s*\[([^\]]+)\]', r'lw \1, 0(\2)', code)
        
        # store rs, [addr] -> sw rs, 0(addr)
        code = re.sub(r'\bstore\s+(\w+),\s*\[([^\]]+)\]', r'sw \1, 0(\2)', code)
        
        # jmp label -> j label
        code = re.sub(r'\bjmp\s+(\w+)', r'j \1', code)
        
        # ret -> ret
        # push reg -> addi sp, sp, -4; sw reg, 0(sp)
        if code.startswith('push'):
            reg = code.split()[1]
            code = f'addi sp, sp, -4\n    sw {reg}, 0(sp)'
        
        # pop reg -> lw reg, 0(sp); addi sp, sp, 4
        if code.startswith('pop'):
            reg = code.split()[1]
            code = f'lw {reg}, 0(sp)\n    addi sp, sp, 4'
        
        # out reg -> li a7, 11; ecall  # for print char
        if code.startswith('out'):
            reg = code.split()[1]
            code = f'li a7, 11\n    ecall  # print char from {reg}'
        
        # halt -> ebreak
        code = re.sub(r'\bhalt\b', 'ebreak', code)
        
        # Registers: replace r0-r31 with x0-x31
        code = re.sub(r'\br(\d+)\b', r'x\1', code)
        
        # Add comment back
        if comment:
            code += ' ' + comment
        
        converted.append(code)
    
    return '\n'.join(converted)

def main():
    if len(sys.argv) != 2:
        print("Usage: python convert.py <file>")
        sys.exit(1)
    
    file_path = sys.argv[1]
    with open(file_path, 'r') as f:
        content = f.read()
    
    converted = convert_to_riscv(content)
    
    # Write back
    with open(file_path, 'w') as f:
        f.write(converted)
    
    print(f"Converted {file_path}")

if __name__ == '__main__':
    main()