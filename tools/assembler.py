#!/usr/bin/env python3
"""
Simple Assembler for 8-bit Microprocessor

Converts assembly language to machine code for the 8-bit microprocessor.
Supports all instructions defined in the ISA.

Usage: pyth            if            if line and not line.startswith(';'):
                # Remove inline comments
                if ';' in line:
                    line = line.split(';')[0].strip()
                
                # Parse instruction
                parts = line.split()
                if not parts:  # Skip if line becomes empty after removing comments
                    continue
                    
                mnemonic = parts[0].upper()
                operands = []
                if len(parts) > 1:
                    operand_str = ' '.join(parts[1:])
                    operands = [op.strip() for op in operand_str.split(',')]d not line.startswith(';'):
                # Remove inline comments
                if ';' in line:
                    line = line.split(';')[0].strip()
                
                # Parse instruction
                parts = line.split()
                if not parts:  # Skip if line becomes empty after removing comments
                    continue
                    
                mnemonic = parts[0].upper()
                operands = []
                if len(parts) > 1:
                    operand_str = ' '.join(parts[1:])
                    operands = [op.strip() for op in operand_str.split(',')]mbler.py input.asm output.hex
"""

import sys
import re

class Assembler:
    def __init__(self):
        # Instruction opcodes
        self.opcodes = {
            # Arithmetic (0x0X)
            'ADD': 0x00, 'SUB': 0x01, 'ADC': 0x02, 'SBC': 0x03,
            'ADDI': 0x04, 'SUBI': 0x05,
            
            # Logic (0x1X) 
            'AND': 0x10, 'OR': 0x11, 'XOR': 0x12, 'NOT': 0x13,
            'ANDI': 0x14, 'ORI': 0x15,
            
            # Shift (0x2X)
            'SHL': 0x20, 'SHR': 0x21, 'ROL': 0x22, 'ROR': 0x23,
            
            # Memory (0x3X)
            'LOAD': 0x30, 'STORE': 0x31, 'LOADI': 0x32,
            'LOADR': 0x33, 'STORER': 0x34,
            
            # Branch (0x4X)
            'JMP': 0x40, 'JEQ': 0x41, 'JNE': 0x42, 'JLT': 0x43,
            'JGE': 0x44, 'JCS': 0x45, 'JCC': 0x46,
            
            # Subroutine (0x5X)
            'CALL': 0x50, 'RET': 0x51, 'PUSH': 0x52, 'POP': 0x53,
            
            # System (0x6X)
            'SYSCALL': 0x60, 'IRET': 0x61, 'EI': 0x62, 'DI': 0x63,
            'HALT': 0x64, 'NOP': 0x65,
            
            # I/O (0x7X)
            'IN': 0x70, 'OUT': 0x71,
            
            # Compare (0x8X)
            'CMP': 0x80, 'CMPI': 0x81
        }
        
        self.labels = {}
        self.machine_code = []
        self.address = 0
        
    def parse_register(self, reg_str):
        """Parse register name (R0-R7) to register number"""
        if reg_str.startswith('R') and len(reg_str) == 2:
            reg_num = int(reg_str[1])
            if 0 <= reg_num <= 7:
                return reg_num
        raise ValueError(f"Invalid register: {reg_str}")
    
    def parse_immediate(self, imm_str):
        """Parse immediate value (#123, #0xFF, etc.)"""
        if imm_str.startswith('#'):
            value_str = imm_str[1:]
            # Remove any comments
            if ';' in value_str:
                value_str = value_str.split(';')[0].strip()
            if value_str.startswith('0x') or value_str.startswith('0X'):
                return int(value_str, 16)
            else:
                return int(value_str)
        raise ValueError(f"Invalid immediate: {imm_str}")
    
    def parse_address(self, addr_str):
        """Parse address (0x1000, label, etc.)"""
        if addr_str.startswith('0x') or addr_str.startswith('0X'):
            return int(addr_str, 16)
        elif addr_str.isdigit():
            return int(addr_str)
        elif addr_str in self.labels:
            return self.labels[addr_str]
        else:
            # Forward reference - will be resolved in second pass
            return 0
    
    def assemble_instruction(self, mnemonic, operands):
        """Assemble a single instruction"""
        if mnemonic not in self.opcodes:
            raise ValueError(f"Unknown instruction: {mnemonic}")
        
        opcode = self.opcodes[mnemonic]
        
        # Handle different instruction formats
        if mnemonic in ['ADD', 'SUB', 'ADC', 'SBC', 'AND', 'OR', 'XOR', 'CMP']:
            # Register-register format
            reg1 = self.parse_register(operands[0])
            reg2 = self.parse_register(operands[1])
            instruction = (opcode << 4) | (reg1 << 1) | (reg2 >> 1)
            return [instruction]
        
        elif mnemonic in ['ADDI', 'SUBI', 'ANDI', 'ORI', 'CMPI']:
            # Register-immediate format
            reg1 = self.parse_register(operands[0])
            immediate = self.parse_immediate(operands[1])
            instruction = (opcode << 4) | (reg1 << 1) | 1  # Set immediate flag
            return [instruction, immediate & 0xFF]
        
        elif mnemonic in ['SHL', 'SHR', 'ROL', 'ROR', 'NOT']:
            # Single register format
            reg1 = self.parse_register(operands[0])
            instruction = (opcode << 4) | (reg1 << 1)
            return [instruction]
        
        elif mnemonic in ['LOAD', 'STORE']:
            # Memory operations with address
            reg1 = self.parse_register(operands[0])
            address = self.parse_address(operands[1])
            instruction = (opcode << 4) | (reg1 << 1)
            return [instruction, address & 0xFF, (address >> 8) & 0xFF]
        
        elif mnemonic == 'LOADI':
            # Load immediate
            reg1 = self.parse_register(operands[0])
            immediate = self.parse_immediate(operands[1])
            instruction = (opcode << 4) | (reg1 << 1)
            return [instruction, immediate & 0xFF]
        
        elif mnemonic in ['LOADR', 'STORER']:
            # Register indirect
            reg1 = self.parse_register(operands[0])
            reg2 = self.parse_register(operands[1])
            instruction = (opcode << 4) | (reg1 << 1) | (reg2 >> 1)
            return [instruction]
        
        elif mnemonic in ['JMP', 'JEQ', 'JNE', 'JLT', 'JGE', 'JCS', 'JCC', 'CALL']:
            # Branch/call with address
            address = self.parse_address(operands[0])
            return [opcode, address & 0xFF, (address >> 8) & 0xFF]
        
        elif mnemonic in ['PUSH', 'POP']:
            # Stack operations
            reg1 = self.parse_register(operands[0])
            instruction = (opcode << 4) | (reg1 << 1)
            return [instruction]
        
        elif mnemonic == 'SYSCALL':
            # System call
            syscall_num = self.parse_immediate(operands[0])
            return [opcode, syscall_num & 0xFF]
        
        elif mnemonic in ['IN', 'OUT']:
            # I/O operations
            reg1 = self.parse_register(operands[0])
            port = self.parse_immediate(operands[1])
            instruction = (opcode << 4) | (reg1 << 1)
            return [instruction, port & 0xFF]
        
        elif mnemonic in ['RET', 'IRET', 'EI', 'DI', 'HALT', 'NOP']:
            # No operand instructions
            return [opcode]
        
        else:
            raise ValueError(f"Unsupported instruction format: {mnemonic}")
    
    def first_pass(self, lines):
        """First pass: collect labels and calculate addresses"""
        self.address = 0
        
        for line in lines:
            line = line.strip()
            if not line or line.startswith(';'):
                continue
            
            # Handle assembler directives
            if line.startswith('.org'):
                parts = line.split()
                if len(parts) > 1:
                    self.address = self.parse_address(parts[1])
                continue
            elif line.startswith('.db'):
                # Data bytes directive
                data_str = line[3:].strip()
                if data_str.startswith('"') and data_str.endswith('"'):
                    # String data
                    string_data = data_str[1:-1]
                    self.address += len(string_data)
                else:
                    # Numeric data
                    values = [v.strip() for v in data_str.split(',')]
                    self.address += len(values)
                continue
            
            # Check for label
            if ':' in line:
                parts = line.split(':', 1)
                label = parts[0].strip()
                self.labels[label] = self.address
                line = parts[1].strip() if len(parts) > 1 else ''
            
            if line and not line.startswith(';'):
                # Parse instruction to calculate size
                parts = line.split()
                mnemonic = parts[0].upper()
                operands = []
                if len(parts) > 1:
                    operand_str = ' '.join(parts[1:])
                    operands = [op.strip() for op in operand_str.split(',')]
                
                # Estimate instruction size
                if mnemonic in ['LOAD', 'STORE', 'JMP', 'JEQ', 'JNE', 'JLT', 'JGE', 'JCS', 'JCC', 'CALL']:
                    self.address += 3  # Instruction + 16-bit address
                elif mnemonic in ['ADDI', 'SUBI', 'ANDI', 'ORI', 'CMPI', 'LOADI', 'SYSCALL', 'IN', 'OUT']:
                    self.address += 2  # Instruction + 8-bit immediate
                else:
                    self.address += 1  # Single byte instruction
    
    def second_pass(self, lines):
        """Second pass: generate machine code"""
        self.machine_code = []
        self.address = 0
        
        for line in lines:
            line = line.strip()
            if not line or line.startswith(';'):
                continue
            
            # Handle assembler directives
            if line.startswith('.org'):
                parts = line.split()
                if len(parts) > 1:
                    self.address = self.parse_address(parts[1])
                    # Pad machine code to reach the new address
                    while len(self.machine_code) < self.address:
                        self.machine_code.append(0x00)
                continue
            elif line.startswith('.db'):
                # Data bytes directive
                data_str = line[3:].strip()
                if data_str.startswith('"'):
                    # String data with escape sequences
                    string_data = data_str[1:-1]
                    string_data = string_data.replace('\\n', '\n').replace('\\r', '\r')
                    for char in string_data:
                        self.machine_code.append(ord(char))
                        self.address += 1
                    # Handle additional values after string
                    if ',' in data_str:
                        remaining = data_str.split(',', 1)[1]
                        values = [v.strip() for v in remaining.split(',')]
                        for val in values:
                            if val.startswith('0x'):
                                self.machine_code.append(int(val, 16))
                            else:
                                self.machine_code.append(int(val))
                            self.address += 1
                else:
                    # Numeric data
                    values = [v.strip() for v in data_str.split(',')]
                    for val in values:
                        if val.startswith('0x'):
                            self.machine_code.append(int(val, 16))
                        else:
                            self.machine_code.append(int(val))
                        self.address += 1
                continue
            
            # Skip label part
            if ':' in line:
                parts = line.split(':', 1)
                line = parts[1].strip() if len(parts) > 1 else ''
            
            if line and not line.startswith(';'):
                # Remove inline comments
                if ';' in line:
                    line = line.split(';')[0].strip()
                
                # Parse instruction
                parts = line.split()
                if not parts:  # Skip if line becomes empty after removing comments
                    continue
                    
                mnemonic = parts[0].upper()
                operands = []
                if len(parts) > 1:
                    operand_str = ' '.join(parts[1:])
                    operands = [op.strip() for op in operand_str.split(',')]
                
                # Generate machine code
                try:
                    machine_code = self.assemble_instruction(mnemonic, operands)
                    self.machine_code.extend(machine_code)
                    self.address += len(machine_code)
                except Exception as e:
                    print(f"Error assembling '{line}': {e}")
                    sys.exit(1)
    
    def assemble(self, source_lines):
        """Assemble source code to machine code"""
        self.first_pass(source_lines)
        self.second_pass(source_lines)
        return self.machine_code

def main():
    if len(sys.argv) != 3:
        print("Usage: python3 assembler.py input.asm output.hex")
        sys.exit(1)
    
    input_file = sys.argv[1]
    output_file = sys.argv[2]
    
    try:
        with open(input_file, 'r') as f:
            source_lines = f.readlines()
        
        assembler = Assembler()
        machine_code = assembler.assemble(source_lines)
        
        # Write output in Intel HEX format
        with open(output_file, 'w') as f:
            f.write("; Machine code for 8-bit microprocessor\\n")
            f.write("; Generated from: {}\\n".format(input_file))
            f.write("\\n")
            
            for i, byte in enumerate(machine_code):
                if i % 16 == 0:
                    f.write(f":{i:04X} ")
                f.write(f"{byte:02X} ")
                if (i + 1) % 16 == 0:
                    f.write("\\n")
            
            if len(machine_code) % 16 != 0:
                f.write("\\n")
        
        print(f"Assembly successful: {len(machine_code)} bytes generated")
        print(f"Output written to: {output_file}")
        
    except FileNotFoundError:
        print(f"Error: Input file '{input_file}' not found")
        sys.exit(1)
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
