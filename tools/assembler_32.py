#!/usr/bin/env python3
"""
32-bit Assembler for 32-bit Microprocessor
Converts assembly language to 32-bit machine code

Instruction Format (32-bit):
- Bits 31-27: Opcode (5 bits)
- Bits 26-24: Function/Subopcode (3 bits)  
- Bits 23-20: Destination Register (4 bits)
- Bits 19-16: Source Register 1 (4 bits)
- Bits 15-12: Source Register 2 (4 bits)
- Bits 11-0:  Immediate/Offset (12 bits, sign-extended)

For large immediates:
- Bits 31-27: Opcode
- Bits 26-20: Destination Register (4 bits)
- Bits 19-0:  20-bit Immediate (sign-extended to 32-bit)
"""

import sys
import re
from pathlib import Path

class Assembler32:
    def __init__(self):
        # 32-bit instruction opcodes (5-bit)
        self.opcodes = {
            'LOADI': 0x01,    # Load immediate (20-bit immediate)
            'LOAD':  0x02,    # Load from memory
            'STORE': 0x03,    # Store to memory
            'ADD':   0x04,    # Add registers
            'ADDI':  0x05,    # Add immediate
            'SUB':   0x06,    # Subtract registers
            'SUBI':  0x07,    # Subtract immediate
            'AND':   0x08,    # Logical AND
            'OR':    0x09,    # Logical OR
            'XOR':   0x0A,    # Logical XOR
            'SHL':   0x0B,    # Shift left
            'SHR':   0x0C,    # Shift right
            'CMP':   0x0D,    # Compare
            'JMP':   0x0E,    # Unconditional jump
            'JZ':    0x0F,    # Jump if zero
            'JNZ':   0x10,    # Jump if not zero
            'JC':    0x11,    # Jump if carry
            'JNC':   0x12,    # Jump if no carry
            'HALT':  0x1F,    # Halt processor
        }
        
        # Register mapping (R0-R15)
        self.registers = {f'R{i}': i for i in range(16)}
        
        self.labels = {}
        self.current_address = 0
        self.instructions = []
        
    def parse_register(self, reg_str):
        """Parse register string to register number"""
        reg_str = reg_str.strip().upper()
        if reg_str in self.registers:
            return self.registers[reg_str]
        else:
            raise ValueError(f"Invalid register: {reg_str}")
    
    def parse_immediate(self, imm_str):
        """Parse immediate value (decimal or hex)"""
        imm_str = imm_str.strip()
        if imm_str.startswith('#'):
            imm_str = imm_str[1:]
        
        if imm_str.startswith('0x') or imm_str.startswith('0X'):
            return int(imm_str, 16)
        else:
            return int(imm_str)
    
    def assemble_instruction(self, opcode, rd=0, rs1=0, rs2=0, immediate=0):
        """Assemble a 32-bit instruction"""
        # Standard format: opcode(5) | func(3) | rd(4) | rs1(4) | rs2(4) | imm(12)
        instruction = (opcode << 27) | (rd << 20) | (rs1 << 16) | (rs2 << 12) | (immediate & 0xFFF)
        return instruction & 0xFFFFFFFF
    
    def assemble_immediate_instruction(self, opcode, rd=0, immediate=0):
        """Assemble instruction with large immediate (20-bit)"""
        # Format: opcode(5) | rd(4) | reserved(3) | immediate(20)
        instruction = (opcode << 27) | (rd << 20) | (immediate & 0xFFFFF)
        return instruction & 0xFFFFFFFF
    
    def first_pass(self, lines):
        """First pass: collect labels and calculate addresses"""
        address = 0
        
        for line_num, line in enumerate(lines, 1):
            line = line.strip()
            if not line or line.startswith(';'):
                continue
            
            # Handle .org directive
            if line.startswith('.org'):
                parts = line.split()
                if len(parts) == 2:
                    address = self.parse_immediate(parts[1])
                    self.current_address = address
                continue
            
            # Handle labels
            if ':' in line:
                label = line.split(':')[0].strip()
                self.labels[label] = address
                # Check if there's an instruction on the same line
                after_colon = line.split(':', 1)[1].strip()
                if after_colon and not after_colon.startswith(';'):
                    address += 4  # 32-bit instructions are 4 bytes
                continue
            
            # Handle data directives
            if line.startswith('.word'):
                address += 4  # 32-bit word
                continue
            elif line.startswith('.byte'):
                address += 1  # Still support 8-bit bytes
                continue
            
            # Regular instruction
            if line and not line.startswith(';'):
                address += 4  # 32-bit instructions
    
    def second_pass(self, lines):
        """Second pass: generate machine code"""
        address = 0
        
        for line_num, line in enumerate(lines, 1):
            original_line = line
            line = line.strip()
            
            if not line or line.startswith(';'):
                continue
            
            try:
                # Handle .org directive
                if line.startswith('.org'):
                    parts = line.split()
                    if len(parts) == 2:
                        address = self.parse_immediate(parts[1])
                    continue
                
                # Handle labels
                if ':' in line:
                    after_colon = line.split(':', 1)[1].strip()
                    if not after_colon or after_colon.startswith(';'):
                        continue
                    line = after_colon
                
                # Handle data directives
                if line.startswith('.word'):
                    parts = line.split()
                    if len(parts) >= 2:
                        value = self.parse_immediate(parts[1])
                        self.instructions.append((address, value, original_line))
                        address += 4
                    continue
                elif line.startswith('.byte'):
                    parts = line.split()
                    if len(parts) >= 2:
                        value = self.parse_immediate(parts[1]) & 0xFF
                        self.instructions.append((address, value, original_line))
                        address += 1
                    continue
                
                # Parse instruction
                parts = line.split()
                if not parts:
                    continue
                
                mnemonic = parts[0].upper()
                if mnemonic not in self.opcodes:
                    print(f"Warning: Unknown instruction '{mnemonic}' on line {line_num}")
                    continue
                
                opcode = self.opcodes[mnemonic]
                machine_code = 0
                
                # Handle different instruction types
                if mnemonic == 'HALT':
                    machine_code = self.assemble_instruction(opcode)
                
                elif mnemonic == 'LOADI':
                    # LOADI Rd, #immediate
                    if len(parts) >= 3:
                        rd = self.parse_register(parts[1].rstrip(','))
                        immediate = self.parse_immediate(parts[2])
                        machine_code = self.assemble_immediate_instruction(opcode, rd, immediate)
                
                elif mnemonic in ['ADD', 'SUB', 'AND', 'OR', 'XOR']:
                    # ADD Rd, Rs1, Rs2
                    if len(parts) >= 4:
                        rd = self.parse_register(parts[1].rstrip(','))
                        rs1 = self.parse_register(parts[2].rstrip(','))
                        rs2 = self.parse_register(parts[3])
                        machine_code = self.assemble_instruction(opcode, rd, rs1, rs2)
                
                elif mnemonic in ['ADDI', 'SUBI']:
                    # ADDI Rd, Rs1, #immediate
                    if len(parts) >= 4:
                        rd = self.parse_register(parts[1].rstrip(','))
                        rs1 = self.parse_register(parts[2].rstrip(','))
                        immediate = self.parse_immediate(parts[3])
                        machine_code = self.assemble_instruction(opcode, rd, rs1, 0, immediate)
                
                elif mnemonic == 'LOAD':
                    # LOAD Rd, [Rs1 + offset] or LOAD Rd, #address
                    if len(parts) >= 3:
                        rd = self.parse_register(parts[1].rstrip(','))
                        if parts[2].startswith('[') and parts[2].endswith(']'):
                            # Memory addressing [Rs1 + offset]
                            addr_part = parts[2][1:-1]  # Remove brackets
                            if '+' in addr_part:
                                reg_part, offset_part = addr_part.split('+')
                                rs1 = self.parse_register(reg_part.strip())
                                offset = self.parse_immediate(offset_part.strip())
                            else:
                                rs1 = self.parse_register(addr_part.strip())
                                offset = 0
                            machine_code = self.assemble_instruction(opcode, rd, rs1, 0, offset)
                        else:
                            # Direct addressing
                            address_val = self.parse_immediate(parts[2])
                            machine_code = self.assemble_immediate_instruction(opcode, rd, address_val)
                
                elif mnemonic == 'STORE':
                    # STORE Rs, [Rd + offset] or STORE Rs, #address
                    if len(parts) >= 3:
                        rs = self.parse_register(parts[1].rstrip(','))
                        if parts[2].startswith('[') and parts[2].endswith(']'):
                            # Memory addressing [Rd + offset]
                            addr_part = parts[2][1:-1]  # Remove brackets
                            if '+' in addr_part:
                                reg_part, offset_part = addr_part.split('+')
                                rd = self.parse_register(reg_part.strip())
                                offset = self.parse_immediate(offset_part.strip())
                            else:
                                rd = self.parse_register(addr_part.strip())
                                offset = 0
                            machine_code = self.assemble_instruction(opcode, rd, rs, 0, offset)
                        else:
                            # Direct addressing
                            address_val = self.parse_immediate(parts[2])
                            machine_code = self.assemble_immediate_instruction(opcode, rs, address_val)
                
                elif mnemonic in ['JMP', 'JZ', 'JNZ', 'JC', 'JNC']:
                    # JMP label or JMP #address
                    if len(parts) >= 2:
                        target = parts[1]
                        if target in self.labels:
                            target_addr = self.labels[target]
                            # Calculate relative offset
                            offset = target_addr - (address + 4)
                            machine_code = self.assemble_instruction(opcode, 0, 0, 0, offset & 0xFFF)
                        else:
                            target_addr = self.parse_immediate(target)
                            machine_code = self.assemble_immediate_instruction(opcode, 0, target_addr)
                
                self.instructions.append((address, machine_code, original_line))
                address += 4
                
            except Exception as e:
                print(f"Error on line {line_num}: {e}")
                print(f"Line: {original_line}")
                continue
    
    def assemble(self, input_file, output_file):
        """Main assembly function"""
        try:
            with open(input_file, 'r') as f:
                lines = f.readlines()
            
            # Two-pass assembly
            self.first_pass(lines)
            self.second_pass(lines)
            
            # Sort instructions by address
            self.instructions.sort(key=lambda x: x[0])
            
            # Write output
            with open(output_file, 'w') as f:
                for addr, code, line in self.instructions:
                    f.write(f"{code:08X}\n")
            
            print(f"Assembly successful: {input_file} -> {output_file}")
            print(f"Generated {len(self.instructions)} instructions")
            
            return True
            
        except Exception as e:
            print(f"Assembly failed: {e}")
            return False

def main():
    if len(sys.argv) != 3:
        print("Usage: python assembler_32.py <input.asm> <output.hex>")
        sys.exit(1)
    
    input_file = sys.argv[1]
    output_file = sys.argv[2]
    
    assembler = Assembler32()
    if assembler.assemble(input_file, output_file):
        sys.exit(0)
    else:
        sys.exit(1)

if __name__ == "__main__":
    main()
