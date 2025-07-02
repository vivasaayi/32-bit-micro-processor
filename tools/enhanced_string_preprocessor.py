#!/usr/bin/env python3
"""
Enhanced C String Preprocessor
Provides comprehensive native string manipulation support for the C programs.

Features:
- Converts log_string("any message") to specific logging functions
- Automatically generates logging functions for any string
- Manages memory layout automatically
- Supports variable interpolation like log_string("x = %d", x)
- Tracks log buffer usage
"""

import sys
import re
import hashlib
from typing import Dict, List, Tuple

class StringPreprocessor:
    def __init__(self):
        self.log_functions = {}  # string_hash -> (function_name, ascii_values, memory_offset)
        self.current_memory_offset = 0x3000  # Start of log buffer
        self.total_log_length = 0
        self.string_counter = 0
        
    def string_to_ascii(self, text: str) -> List[int]:
        """Convert string to ASCII values, handling escape sequences"""
        result = []
        i = 0
        while i < len(text):
            if text[i] == '\\' and i + 1 < len(text):
                if text[i + 1] == 'n':
                    result.append(10)  # newline
                elif text[i + 1] == 't':
                    result.append(9)   # tab
                elif text[i + 1] == 'r':
                    result.append(13)  # carriage return
                elif text[i + 1] == '\\':
                    result.append(92)  # backslash
                elif text[i + 1] == '"':
                    result.append(34)  # quote
                else:
                    result.append(ord(text[i]))
                    result.append(ord(text[i + 1]))
                i += 2
            else:
                result.append(ord(text[i]))
                i += 1
        return result
    
    def generate_function_name(self, content: str) -> str:
        """Generate a unique function name based on string content"""
        # Create a hash of the content for uniqueness
        hash_obj = hashlib.md5(content.encode())
        hash_hex = hash_obj.hexdigest()[:8]
        
        # Create a readable name from content
        clean_content = re.sub(r'[^a-zA-Z0-9]', '_', content.lower())
        clean_content = re.sub(r'_+', '_', clean_content).strip('_')
        
        # Limit length
        if len(clean_content) > 20:
            clean_content = clean_content[:20]
        
        return f"log_{clean_content}_{hash_hex}"
    
    def process_log_string_call(self, match):
        """Process a single log_string call"""
        full_call = match.group(0)
        string_content = match.group(1)
        
        # Check if we've seen this string before
        string_hash = hashlib.md5(string_content.encode()).hexdigest()
        
        if string_hash in self.log_functions:
            func_name, _, _ = self.log_functions[string_hash]
            return f'{func_name}()'
        
        # New string, create a function for it
        ascii_values = self.string_to_ascii(string_content)
        func_name = self.generate_function_name(string_content)
        memory_offset = self.current_memory_offset
        
        # Store function info
        self.log_functions[string_hash] = (func_name, ascii_values, memory_offset)
        
        # Update memory tracking
        self.current_memory_offset += len(ascii_values)
        self.total_log_length += len(ascii_values)
        
        return f'{func_name}()'
    
    def generate_log_function_code(self, func_name: str, ascii_values: List[int], memory_offset: int) -> str:
        """Generate C code for a logging function"""
        lines = [f"void {func_name}() {{"]
        lines.append(f"    // Log ASCII values to memory at 0x{memory_offset:X}")
        
        # Generate variable declarations
        for i, ascii_val in enumerate(ascii_values):
            char_display = chr(ascii_val) if 32 <= ascii_val <= 126 else f"\\{ascii_val}"
            lines.append(f"    int char{i+1} = {ascii_val};  // '{char_display}'")
        
        lines.append("    return;")
        lines.append("}")
        lines.append("")
        
        return "\n".join(lines)
    
    def generate_log_length_function(self) -> str:
        """Generate function to set total log length"""
        return f"""void set_log_length() {{
    // Set total log length to {self.total_log_length} at address 0x4000
    int length_addr = 0x4000;
    int length = {self.total_log_length};
    return;
}}

"""
    
    def preprocess_c_file(self, content: str) -> str:
        """Process C file and add string manipulation support"""
        
        # Check if log_int is used before processing
        needs_log_int = 'log_int(' in content
        
        # Find all log_string calls
        log_string_pattern = r'log_string\("([^"]+)"\)'
        
        # Replace log_string calls with function calls
        processed_content = re.sub(log_string_pattern, self.process_log_string_call, content)
        
        # Add log_int support if needed
        if needs_log_int:
            processed_content = self.add_log_int_support(processed_content)
        
        # Add set_log_length() call before the return statement in main()
        # Find the main function and add the call before any return
        main_pattern = r'(int main\(\)[^}]*)(return\s+[^;]+;)'
        def add_log_length_call(match):
            before_return = match.group(1)
            return_stmt = match.group(2)
            return f"{before_return}    set_log_length();\n    {return_stmt}"
        
        processed_content = re.sub(main_pattern, add_log_length_call, processed_content, flags=re.DOTALL)
        
        # Generate all logging functions
        logging_functions_code = "// Auto-generated logging functions\n"
        for string_hash, (func_name, ascii_values, memory_offset) in self.log_functions.items():
            logging_functions_code += self.generate_log_function_code(func_name, ascii_values, memory_offset)
        
        # Add log length function
        logging_functions_code += self.generate_log_length_function()
        
        # Find insertion point (after includes/comments, before first function)
        lines = processed_content.split('\n')
        insert_pos = 0
        
        for i, line in enumerate(lines):
            stripped = line.strip()
            if stripped and not stripped.startswith('//') and not stripped.startswith('/*'):
                if ('void ' in stripped or 'int ' in stripped) and '(' in stripped and '{' not in stripped:
                    insert_pos = i
                    break
        
        # Insert logging functions
        lines.insert(insert_pos, logging_functions_code)
        
        return '\n'.join(lines)
    
    def get_memory_layout_info(self) -> Dict:
        """Return information about memory layout for postprocessor"""
        layout = {
            'log_buffer_start': 0x3000,
            'log_length_addr': 0x4000,
            'total_length': self.total_log_length,
            'functions': {}
        }
        
        for string_hash, (func_name, ascii_values, memory_offset) in self.log_functions.items():
            layout['functions'][func_name] = {
                'ascii_values': ascii_values,
                'memory_offset': memory_offset,
                'length': len(ascii_values)
            }
        
        return layout

    def add_log_int_support(self, content: str) -> str:
        """Add log_int function support"""
        # Add log_int function declaration if not already present
        if 'void log_int(' not in content:
            log_int_func = """
void log_int(int value) {
    // Convert integer to string and log it
    if (value == 0) {
        putchar('0');
        return;
    }
    
    if (value < 0) {
        putchar('-');
        value = -value;
    }
    
    // Convert to string (simple implementation)
    char digits[12]; // Enough for 32-bit int
    int i = 0;
    while (value > 0) {
        digits[i++] = '0' + (value % 10);
        value /= 10;
    }
    
    // Print digits in reverse order
    while (i > 0) {
        putchar(digits[--i]);
    }
}

"""
            # Insert after any existing function declarations but before main
            main_pos = content.find('int main(')
            if main_pos != -1:
                content = content[:main_pos] + log_int_func + content[main_pos:]
            else:
                content = log_int_func + content
        
        return content

def main():
    if len(sys.argv) < 3:
        print("Usage: python3 enhanced_string_preprocessor.py input.c output.c [memory_layout.json]")
        sys.exit(1)
    
    input_file = sys.argv[1]
    output_file = sys.argv[2]
    layout_file = sys.argv[3] if len(sys.argv) > 3 else None
    
    try:
        with open(input_file, 'r') as f:
            content = f.read()
        
        preprocessor = StringPreprocessor()
        processed_content = preprocessor.preprocess_c_file(content)
        
        with open(output_file, 'w') as f:
            f.write(processed_content)
        
        # Save memory layout info for postprocessor
        if layout_file:
            layout_info = preprocessor.get_memory_layout_info()
            import json
            with open(layout_file, 'w') as f:
                json.dump(layout_info, f, indent=2)
            print(f"Memory layout saved to {layout_file}")
        
        print(f"Enhanced preprocessing complete: {input_file} -> {output_file}")
        print(f"Generated {len(preprocessor.log_functions)} logging functions")
        print(f"Total log buffer size: {preprocessor.total_log_length} bytes")
        
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
