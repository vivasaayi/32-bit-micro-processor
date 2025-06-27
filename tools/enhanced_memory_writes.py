#!/usr/bin/env python3
"""
Enhanced Memory Write Postprocessor
Uses memory layout information to intelligently add STORE instructions.

Features:
- Reads memory layout from JSON file
- Generates optimized STORE instructions
- Handles both direct addressing and register+offset modes
- Automatically manages memory addresses
"""

import sys
import re
import json
from typing import Dict, List, Tuple

class EnhancedMemoryWritePostprocessor:
    def __init__(self, memory_layout: Dict = None):
        self.memory_layout = memory_layout or {}
        self.functions = self.memory_layout.get('functions', {})
        
    def generate_store_instructions(self, func_name: str, ascii_values: List[int], memory_offset: int) -> List[str]:
        """Generate STORE instructions for a logging function"""
        instructions = []
        
        # Use register+offset addressing 
        # Load base address into a register first
        base_addr = memory_offset
        
        instructions.extend([
            f"; Set up base address for logging function {func_name}",
            f"LOADI R31, #0x{base_addr:X}",
            ""
        ])
        
        for i, ascii_val in enumerate(ascii_values):
            char_display = chr(ascii_val) if 32 <= ascii_val <= 126 else f"\\{ascii_val}"
            instructions.extend([
                f"; Store ASCII {ascii_val} ('{char_display}') to 0x{base_addr + i:X}",
                f"LOADI R0, #{ascii_val}",
                f"STORE R0, R31, #{i}",
                ""
            ])
        
        return instructions
    
    def generate_length_store_instruction(self) -> List[str]:
        """Generate instruction to store total log length"""
        total_length = self.memory_layout.get('total_length', 0)
        length_addr = self.memory_layout.get('log_length_addr', 0x4000)
        
        return [
            f"; Store total log length {total_length} to 0x{length_addr:X}",
            f"LOADI R31, #0x{length_addr:X}",
            f"LOADI R0, #{total_length}",
            f"STORE R0, R31, #0",
            ""
        ]
    
    def find_function_in_assembly(self, asm_content: str, func_name: str) -> Tuple[int, int]:
        """Find start and end positions of a function in assembly"""
        lines = asm_content.split('\n')
        
        start_idx = -1
        end_idx = -1
        
        for i, line in enumerate(lines):
            if line.strip() == f"{func_name}:":
                start_idx = i
            elif start_idx != -1 and (line.strip() == "RET" or line.strip() == "HALT"):
                end_idx = i
                break
        
        return start_idx, end_idx
    
    def add_memory_writes_to_function(self, asm_content: str, func_name: str) -> str:
        """Add memory write instructions to a specific function"""
        if func_name not in self.functions:
            print(f"Warning: No memory layout info for function {func_name}")
            return asm_content
        
        func_info = self.functions[func_name]
        ascii_values = func_info['ascii_values']
        memory_offset = func_info['memory_offset']
        
        start_idx, end_idx = self.find_function_in_assembly(asm_content, func_name)
        
        if start_idx == -1 or end_idx == -1:
            print(f"Warning: Function {func_name} not found in assembly")
            return asm_content
        
        lines = asm_content.split('\n')
        
        # Generate STORE instructions
        store_instructions = self.generate_store_instructions(func_name, ascii_values, memory_offset)
        
        # Insert before RET
        for instruction in reversed(store_instructions):
            lines.insert(end_idx, instruction)
        
        return '\n'.join(lines)
    
    def add_length_store_to_function(self, asm_content: str, func_name: str = "set_log_length") -> str:
        """Add log length store instruction to the length function"""
        start_idx, end_idx = self.find_function_in_assembly(asm_content, func_name)
        
        if start_idx == -1 or end_idx == -1:
            print(f"Warning: Function {func_name} not found in assembly")
            return asm_content
        
        lines = asm_content.split('\n')
        
        # Generate length store instruction
        length_instructions = self.generate_length_store_instruction()
        
        # Insert before RET
        for instruction in reversed(length_instructions):
            lines.insert(end_idx, instruction)
        
        return '\n'.join(lines)
    
    def process_assembly(self, asm_content: str) -> str:
        """Process assembly file and add all memory write instructions"""
        result = asm_content
        
        # Add memory writes for all logging functions
        for func_name in self.functions.keys():
            result = self.add_memory_writes_to_function(result, func_name)
        
        # Add length store instruction
        result = self.add_length_store_to_function(result)
        
        return result
    
    def optimize_stores(self, asm_content: str) -> str:
        """Optimize STORE instructions for better performance"""
        lines = asm_content.split('\n')
        optimized_lines = []
        
        i = 0
        while i < len(lines):
            line = lines[i].strip()
            
            # Look for consecutive LOADI/STORE pairs that could be optimized
            if line.startswith('LOADI R0,') and i + 1 < len(lines):
                next_line = lines[i + 1].strip()
                if next_line.startswith('STORE R0,'):
                    # Keep as is for now - could optimize later with multi-store instructions
                    optimized_lines.append(lines[i])
                    optimized_lines.append(lines[i + 1])
                    i += 2
                    continue
            
            optimized_lines.append(lines[i])
            i += 1
        
        return '\n'.join(optimized_lines)

def main():
    if len(sys.argv) < 3:
        print("Usage: python3 enhanced_memory_writes.py input.asm output.asm [memory_layout.json]")
        sys.exit(1)
    
    input_file = sys.argv[1]
    output_file = sys.argv[2]
    layout_file = sys.argv[3] if len(sys.argv) > 3 else None
    
    try:
        # Load memory layout if provided
        memory_layout = {}
        if layout_file:
            try:
                with open(layout_file, 'r') as f:
                    memory_layout = json.load(f)
                print(f"Loaded memory layout from {layout_file}")
            except FileNotFoundError:
                print(f"Warning: Memory layout file {layout_file} not found, using default")
        
        # Read input assembly
        with open(input_file, 'r') as f:
            asm_content = f.read()
        
        # Process assembly
        postprocessor = EnhancedMemoryWritePostprocessor(memory_layout)
        modified_content = postprocessor.process_assembly(asm_content)
        modified_content = postprocessor.optimize_stores(modified_content)
        
        # Write output
        with open(output_file, 'w') as f:
            f.write(modified_content)
        
        print(f"Enhanced memory writes added: {input_file} -> {output_file}")
        if memory_layout:
            print(f"Processed {len(postprocessor.functions)} logging functions")
        
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
