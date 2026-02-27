#!/usr/bin/env python3
"""
Simple bytecode converter for AruviJVM
Converts Java bytecode (from javap output) to AruviJVM bytecode arrays
"""

import re
import sys

# Mapping of Java bytecode mnemonics to AruviJVM opcodes
OPCODE_MAP = {
    'nop': 0x00,
    'iconst_m1': 0x02,
    'iconst_0': 0x03,
    'iconst_1': 0x04,
    'iconst_2': 0x05,
    'iconst_3': 0x06,
    'iconst_4': 0x07,
    'iconst_5': 0x08,
    'bipush': 0x10,
    'sipush': 0x11,
    'iload': 0x15,
    'iload_0': 0x1a,
    'iload_1': 0x1b,
    'iload_2': 0x1c,
    'iload_3': 0x1d,
    'istore': 0x36,
    'istore_0': 0x3b,
    'istore_1': 0x3c,
    'istore_2': 0x3d,
    'istore_3': 0x3e,
    'iadd': 0x60,
    'isub': 0x64,
    'imul': 0x68,
    'idiv': 0x6c,
    'irem': 0x70,
    'ineg': 0x74,
    'if_icmpeq': 0x9f,
    'if_icmpne': 0xa0,
    'if_icmplt': 0xa1,
    'if_icmpge': 0xa2,
    'if_icmpgt': 0xa3,
    'if_icmple': 0xa4,
    'goto': 0xa7,
    'ireturn': 0xac,
    'return': 0xb1,
    'invokestatic': 0xb8,
    'halt': 0xff
}

def parse_javap_output(lines):
    """Parse javap -c output and extract bytecode instructions"""
    instructions = []
    
    for line in lines:
        line = line.strip()
        
        # Skip empty lines and non-instruction lines
        if not line or not re.match(r'\s*\d+:', line):
            continue
            
        # Parse instruction line: "   0: iconst_5"
        match = re.match(r'\s*(\d+):\s+(\w+)(?:\s+(.+))?', line)
        if match:
            pc = int(match.group(1))
            mnemonic = match.group(2)
            operand = match.group(3) if match.group(3) else None
            
            instructions.append({
                'pc': pc,
                'mnemonic': mnemonic,
                'operand': operand
            })
    
    return instructions

def convert_to_bytecode(instructions):
    """Convert parsed instructions to AruviJVM bytecode array"""
    bytecode = []
    
    for instr in instructions:
        mnemonic = instr['mnemonic']
        operand = instr['operand']
        
        if mnemonic in OPCODE_MAP:
            bytecode.append(OPCODE_MAP[mnemonic])
            
            # Handle operands
            if operand is not None:
                if mnemonic in ['bipush']:
                    # Single byte operand
                    value = int(operand)
                    bytecode.append(value & 0xFF)
                elif mnemonic in ['sipush']:
                    # Two byte operand (big endian)
                    value = int(operand)
                    bytecode.append((value >> 8) & 0xFF)
                    bytecode.append(value & 0xFF)
                elif mnemonic in ['iload', 'istore']:
                    # Local variable index
                    bytecode.append(int(operand))
                elif mnemonic in ['if_icmpeq', 'if_icmpne', 'if_icmplt', 
                                'if_icmpge', 'if_icmpgt', 'if_icmple', 'goto']:
                    # Branch offset (usually needs manual calculation)
                    offset = int(operand)
                    bytecode.append((offset >> 8) & 0xFF)
                    bytecode.append(offset & 0xFF)
        else:
            print(f"Warning: Unsupported instruction: {mnemonic}")
    
    return bytecode

def format_c_array(bytecode, name="bytecode"):
    """Format bytecode as C array"""
    result = f"uint8_t {name}[] = {{\n"
    
    for i, byte in enumerate(bytecode):
        if i % 8 == 0:
            result += "    "
        
        result += f"0x{byte:02x}"
        
        if i < len(bytecode) - 1:
            result += ", "
        
        if (i + 1) % 8 == 0 or i == len(bytecode) - 1:
            result += "\n"
    
    result += "};"
    return result

def main():
    if len(sys.argv) != 2:
        print("Usage: python3 bytecode_converter.py <javap_output_file>")
        print("       or")
        print("       javap -c ClassName | python3 bytecode_converter.py -")
        sys.exit(1)
    
    filename = sys.argv[1]
    
    try:
        if filename == '-':
            lines = sys.stdin.readlines()
        else:
            with open(filename, 'r') as f:
                lines = f.readlines()
        
        instructions = parse_javap_output(lines)
        
        if not instructions:
            print("No bytecode instructions found in input")
            sys.exit(1)
        
        bytecode = convert_to_bytecode(instructions)
        c_array = format_c_array(bytecode)
        
        print("// Converted AruviJVM bytecode")
        print(c_array)
        print(f"\n// Array size: {len(bytecode)} bytes")
        
    except FileNotFoundError:
        print(f"Error: File '{filename}' not found")
        sys.exit(1)
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
