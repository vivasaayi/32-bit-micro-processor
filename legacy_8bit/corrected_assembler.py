#!/usr/bin/env python3
"""
Corrected Assembler for 8-bit Microprocessor

Fixed to match the CPU control unit's expected instruction encoding.
"""

import sys
import re

class CorrectedAssembler:
    def __init__(self):
        # Updated opcodes to match control_unit.v
        self.opcodes = {
            # Arithmetic (opcode 0x0)
            'ADD': 0x0, 'SUB': 0x1, 'ADC': 0x1, 'SBC': 0x1,  # SUB variants use same opcode, different sub-op
            
            # Logic (opcode 0x2) 
            'AND': 0x2, 'OR': 0x2, 'XOR': 0x2, 'NOT': 0x2,  # Logic ops use same opcode, different sub-op
            
            # Shift (opcode 0x3)
            'SHL': 0x3, 'SHR': 0x3, 'ROL': 0x3, 'ROR': 0x3,  # Shift ops use same opcode, different sub-op
            
            # Memory (opcode 0x4)
            'LOAD': 0x4, 'STORE': 0x4, 'LOADI': 0x4, 'LOADR': 0x4, 'STORER': 0x4,
            
            # Branch (opcode 0x5)
            'JMP': 0x5, 'JEQ': 0x5, 'JNE': 0x5, 'JLT': 0x5, 'JGE': 0x5, 'JCS': 0x5, 'JCC': 0x5,
            
            # Subroutine (opcode 0x6)
            'CALL': 0x6, 'RET': 0x6, 'PUSH': 0x6, 'POP': 0x6,
            
            # System (opcode 0x7)
            'SYSCALL': 0x7, 'IRET': 0x7, 'EI': 0x7, 'DI': 0x7, 'HALT': 0x7, 'NOP': 0x7,
            
            # Compare (opcode 0x8)
            'CMP': 0x8
        }
        
        # Sub-operation codes
        self.sub_ops = {
            # ALU sub-ops for opcode 0x1 (SUB family)
            'SUB': 0x0, 'ADC': 0x2, 'SBC': 0x3,
            
            # Logic sub-ops for opcode 0x2
            'AND': 0x0, 'OR': 0x1, 'XOR': 0x2, 'NOT': 0x3,
            
            # Shift sub-ops for opcode 0x3
            'SHL': 0x0, 'SHR': 0x1, 'ROL': 0x2, 'ROR': 0x3,
            
            # Memory sub-ops for opcode 0x4
            'LOAD': 0x0, 'STORE': 0x1, 'LOADI': 0x2, 'LOADR': 0x3, 'STORER': 0x3,
            
            # Branch sub-ops for opcode 0x5
            'JMP': 0x0, 'JEQ': 0x1, 'JNE': 0x2, 'JLT': 0x3, 'JGE': 0x4, 'JCS': 0x5, 'JCC': 0x6,
            
            # Subroutine sub-ops for opcode 0x6
            'CALL': 0x0, 'RET': 0x1, 'PUSH': 0x2, 'POP': 0x3
        }
        
        # System instruction specific codes
        self.system_codes = {
            'SYSCALL': 0x60, 'IRET': 0x61, 'EI': 0x62, 'DI': 0x63, 'HALT': 0x64, 'NOP': 0x65
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
            return 0  # Forward reference
    
    def assemble_instruction(self, mnemonic, operands):
        """Assemble instruction with correct encoding for control_unit.v"""
        if mnemonic not in self.opcodes:
            raise ValueError(f"Unknown instruction: {mnemonic}")
        
        opcode = self.opcodes[mnemonic]
        
        # Based on control_unit.v instruction decoding:
        # instruction[7:4] = opcode
        # instruction[3:1] = reg1  
        # instruction[1:0] = reg2 or sub-operation
        
        if mnemonic == 'ADD':
            # ADD R0, R1 -> opcode=0, reg1=R0, reg2=R1
            reg1 = self.parse_register(operands[0]) 
            reg2 = self.parse_register(operands[1])
            instruction = (opcode << 4) | (reg1 << 1) | (reg2 >> 1)
            return [instruction]
            
        elif mnemonic in ['SUB', 'ADC', 'SBC']:
            # SUB family uses opcode 1 with sub-operation in bits [1:0]
            reg1 = self.parse_register(operands[0])
            reg2 = self.parse_register(operands[1]) 
            sub_op = self.sub_ops[mnemonic]
            instruction = (opcode << 4) | (reg1 << 1) | sub_op
            return [instruction]
            
        elif mnemonic in ['AND', 'OR', 'XOR', 'NOT']:
            # Logic ops use opcode 2 with sub-operation in bits [1:0]
            reg1 = self.parse_register(operands[0])
            if mnemonic != 'NOT':
                reg2 = self.parse_register(operands[1])
            else:
                reg2 = 0  # NOT is unary
            sub_op = self.sub_ops[mnemonic]
            instruction = (opcode << 4) | (reg1 << 1) | sub_op
            return [instruction]
            
        elif mnemonic in ['SHL', 'SHR', 'ROL', 'ROR']:
            # Shift ops use opcode 3 with sub-operation in bits [1:0]
            reg1 = self.parse_register(operands[0])
            sub_op = self.sub_ops[mnemonic]
            instruction = (opcode << 4) | (reg1 << 1) | sub_op
            return [instruction]
            
        elif mnemonic == 'LOADI':
            # LOADI uses opcode 4 with sub-operation 2 (0x42 base)
            reg1 = self.parse_register(operands[0])
            immediate = self.parse_immediate(operands[1])
            instruction = (opcode << 4) | (reg1 << 1) | 0x2  # sub-op = 2 for LOADI
            return [instruction, immediate & 0xFF]
            
        elif mnemonic in ['LOAD', 'STORE']:
            # Memory ops use opcode 4 with sub-operation in bits [1:0]
            reg1 = self.parse_register(operands[0])
            address = self.parse_address(operands[1])
            sub_op = self.sub_ops[mnemonic]
            instruction = (opcode << 4) | (reg1 << 1) | sub_op
            return [instruction, address & 0xFF, (address >> 8) & 0xFF]
            
        elif mnemonic in ['JMP', 'JEQ', 'JNE', 'JLT', 'JGE', 'JCS', 'JCC']:
            # Branch ops use opcode 5 with sub-operation in bits [2:0]
            address = self.parse_address(operands[0])
            sub_op = self.sub_ops[mnemonic]
            instruction = (opcode << 4) | sub_op  # Sub-op in lower 3 bits
            return [instruction, address & 0xFF, (address >> 8) & 0xFF]
            
        elif mnemonic == 'CMP':
            # CMP uses opcode 8
            reg1 = self.parse_register(operands[0])
            reg2 = self.parse_register(operands[1])
            instruction = (opcode << 4) | (reg1 << 1) | (reg2 >> 1)
            return [instruction]
            
        elif mnemonic in ['CALL', 'RET', 'PUSH', 'POP']:
            # Subroutine ops use opcode 6 with sub-operation in bits [1:0]
            sub_op = self.sub_ops[mnemonic]
            if mnemonic in ['PUSH', 'POP']:
                reg1 = self.parse_register(operands[0])
                instruction = (opcode << 4) | (reg1 << 1) | sub_op
            else:
                instruction = (opcode << 4) | sub_op
            return [instruction]
            
        elif mnemonic in ['SYSCALL', 'IRET', 'EI', 'DI', 'HALT', 'NOP']:
            # System instructions use specific codes
            return [self.system_codes[mnemonic]]
            
        else:
            raise ValueError(f"Unsupported instruction: {mnemonic}")

    def first_pass(self, lines):
        """First pass: collect labels"""
        self.address = 0
        
        for line in lines:
            line = line.strip()
            if not line or line.startswith(';'):
                continue
                
            # Handle .org directive
            if line.startswith('.org'):
                addr_str = line.split()[1]
                self.address = self.parse_address(addr_str)
                continue
                
            # Handle labels
            if ':' in line:
                parts = line.split(':')
                label = parts[0].strip()
                self.labels[label] = self.address
                
                # Process instruction after label if present
                if len(parts) > 1 and parts[1].strip():
                    line = parts[1].strip()
                else:
                    continue
            
            if line and not line.startswith(';'):
                # Remove inline comments
                if ';' in line:
                    line = line.split(';')[0].strip()
                
                parts = line.split()
                if not parts:
                    continue
                    
                mnemonic = parts[0].upper()
                operands = []
                if len(parts) > 1:
                    operand_str = ' '.join(parts[1:])
                    operands = [op.strip() for op in operand_str.split(',')]
                
                try:
                    machine_code = self.assemble_instruction(mnemonic, operands)
                    self.address += len(machine_code)
                except ValueError as e:
                    print(f"Error in first pass: {e}")
    
    def second_pass(self, lines):
        """Second pass: generate machine code"""
        self.address = 0
        self.machine_code = []
        
        for line in lines:
            line = line.strip()
            if not line or line.startswith(';'):
                continue
                
            # Handle .org directive
            if line.startswith('.org'):
                addr_str = line.split()[1]
                self.address = self.parse_address(addr_str)
                continue
                
            # Handle labels
            if ':' in line:
                parts = line.split(':')
                if len(parts) > 1 and parts[1].strip():
                    line = parts[1].strip()
                else:
                    continue
            
            if line and not line.startswith(';'):
                # Remove inline comments
                if ';' in line:
                    line = line.split(';')[0].strip()
                
                parts = line.split()
                if not parts:
                    continue
                    
                mnemonic = parts[0].upper()
                operands = []
                if len(parts) > 1:
                    operand_str = ' '.join(parts[1:])
                    operands = [op.strip() for op in operand_str.split(',')]
                
                try:
                    machine_code = self.assemble_instruction(mnemonic, operands)
                    for byte in machine_code:
                        self.machine_code.append((self.address, byte))
                        self.address += 1
                except ValueError as e:
                    print(f"Error assembling {line}: {e}")
    
    def generate_hex(self):
        """Generate Intel HEX format output"""
        if not self.machine_code:
            return []
        
        lines = []
        lines.append("; Machine code for 8-bit microprocessor")
        lines.append(f"; Generated from corrected assembler")
        lines.append("")
        
        # Group by 16-byte chunks
        current_addr = None
        current_data = []
        
        for addr, byte in self.machine_code:
            if current_addr is None:
                current_addr = addr & 0xFFF0  # Align to 16-byte boundary
            
            # If we're beyond the current 16-byte chunk, output it
            if addr >= current_addr + 16:
                if current_data:
                    hex_data = ' '.join(f'{b:02X}' for b in current_data)
                    lines.append(f':{current_addr:04X} {hex_data}')
                current_addr = addr & 0xFFF0
                current_data = [0] * 16
            
            # Ensure we have the right size array
            if len(current_data) < 16:
                current_data = [0] * 16
                
            # Insert byte at correct position
            offset = addr - current_addr
            if 0 <= offset < 16:
                current_data[offset] = byte
        
        # Output final chunk
        if current_data:
            hex_data = ' '.join(f'{b:02X}' for b in current_data)
            lines.append(f':{current_addr:04X} {hex_data}')
        
        return lines

def main():
    if len(sys.argv) != 3:
        print("Usage: python corrected_assembler.py input.asm output.hex")
        sys.exit(1)
    
    input_file = sys.argv[1]
    output_file = sys.argv[2]
    
    assembler = CorrectedAssembler()
    
    try:
        with open(input_file, 'r') as f:
            lines = f.readlines()
        
        print(f"First pass...")
        assembler.first_pass(lines)
        print(f"Found {len(assembler.labels)} labels: {assembler.labels}")
        
        print(f"Second pass...")
        assembler.second_pass(lines)
        print(f"Generated {len(assembler.machine_code)} bytes of machine code")
        
        print(f"Writing hex file...")
        hex_lines = assembler.generate_hex()
        
        with open(output_file, 'w') as f:
            for line in hex_lines:
                f.write(line + '\n')
        
        print(f"Assembly complete: {input_file} -> {output_file}")
        
        # Show first few instructions for verification
        print("\nFirst few instructions:")
        for i, (addr, byte) in enumerate(assembler.machine_code[:20]):
            print(f"  {addr:04X}: {byte:02X}")
            
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
