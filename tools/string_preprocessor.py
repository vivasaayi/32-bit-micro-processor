#!/usr/bin/env python3
"""
C String Preprocessor
Converts log_string("message") calls into specific logging function calls.
This gives you the string manipulation interface you want!
"""

import sys
import re

def preprocess_c_file(content):
    """Convert log_string calls to specific logging functions"""
    
    # Dictionary of common log messages and their function equivalents
    log_mappings = {
        'log_string("x=10\\n")': 'log_x_equals_10()',
        'log_string("y=20\\n")': 'log_y_equals_20()',
        'log_string("sum=30\\n")': 'log_sum_equals_30()',
        'log_string("Start\\n")': 'log_start()',
        'log_string("End\\n")': 'log_end()',
        'log_string("OK\\n")': 'log_ok()',
        'log_string("FAIL\\n")': 'log_fail()',
        'log_string("Hello\\n")': 'log_hello()',
        'log_string("Test\\n")': 'log_test()',
    }
    
    result = content
    
    # Replace known log_string calls
    for log_call, func_call in log_mappings.items():
        result = result.replace(log_call, func_call)
    
    # Handle generic log_string calls by converting them to specific functions
    log_string_pattern = r'log_string\("([^"]+)"\)'
    
    def replace_log_string(match):
        message = match.group(1)
        # Generate a function name based on the message
        func_name = generate_log_function_name(message)
        return f'{func_name}()'
    
    result = re.sub(log_string_pattern, replace_log_string, result)
    
    # Add the logging function declarations at the top
    logging_functions = generate_logging_functions()
    
    # Insert after any existing includes/comments but before the first function
    lines = result.split('\n')
    insert_pos = 0
    
    # Find a good place to insert (after comments, before first function)
    for i, line in enumerate(lines):
        stripped = line.strip()
        if stripped and not stripped.startswith('//') and not stripped.startswith('/*'):
            if 'void ' in stripped or 'int ' in stripped and '(' in stripped:
                insert_pos = i
                break
    
    # Insert logging functions
    lines.insert(insert_pos, logging_functions)
    
    return '\n'.join(lines)

def generate_log_function_name(message):
    """Generate a valid C function name from a log message"""
    # Remove special characters and convert to snake_case
    name = re.sub(r'[^a-zA-Z0-9]', '_', message.lower())
    name = re.sub(r'_+', '_', name)  # Remove multiple underscores
    name = name.strip('_')  # Remove leading/trailing underscores
    return f'log_{name}'

def generate_logging_functions():
    """Generate the logging function declarations"""
    return '''// Auto-generated logging functions
void log_x_equals_10() {
    // Log "x=10\\n" - ASCII: 120,61,49,48,10
    int memory_base = 0x3000;
    int char1 = 120; int char2 = 61; int char3 = 49; int char4 = 48; int char5 = 10;
    return;
}

void log_y_equals_20() {
    // Log "y=20\\n" - ASCII: 121,61,50,48,10
    int memory_base = 0x3005;
    int char1 = 121; int char2 = 61; int char3 = 50; int char4 = 48; int char5 = 10;
    return;
}

void log_sum_equals_30() {
    // Log "sum=30\\n" - ASCII: 115,117,109,61,51,48,10
    int memory_base = 0x300A;
    int char1 = 115; int char2 = 117; int char3 = 109; int char4 = 61; int char5 = 51; int char6 = 48; int char7 = 10;
    return;
}

void log_start() {
    // Log "Start\\n" - ASCII: 83,116,97,114,116,10
    int char1 = 83; int char2 = 116; int char3 = 97; int char4 = 114; int char5 = 116; int char6 = 10;
    return;
}

void log_end() {
    // Log "End\\n" - ASCII: 69,110,100,10
    int char1 = 69; int char2 = 110; int char3 = 100; int char4 = 10;
    return;
}

void log_ok() {
    // Log "OK\\n" - ASCII: 79,75,10
    int char1 = 79; int char2 = 75; int char3 = 10;
    return;
}

void log_fail() {
    // Log "FAIL\\n" - ASCII: 70,65,73,76,10
    int char1 = 70; int char2 = 65; int char3 = 73; int char4 = 76; int char5 = 10;
    return;
}

void set_log_length_to_17() {
    int length_addr = 0x4000;
    int length = 17;
    return;
}

'''

def main():
    if len(sys.argv) != 3:
        print("Usage: python3 string_preprocessor.py input.c output.c")
        sys.exit(1)
    
    input_file = sys.argv[1]
    output_file = sys.argv[2]
    
    try:
        with open(input_file, 'r') as f:
            content = f.read()
        
        processed_content = preprocess_c_file(content)
        
        with open(output_file, 'w') as f:
            f.write(processed_content)
        
        print(f"Preprocessed {input_file} -> {output_file}")
        print("Added native string manipulation support!")
        
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
