#!/usr/bin/env python3
"""
Java-to-RISC Execution Pipeline

This script provides a complete pipeline for:
1. Compiling Java source to bytecode
2. Extracting bytecode from .class files
3. Running bytecode through our JVM interpreter on the RISC processor
"""

import os
import sys
import subprocess
import json
import argparse
from pathlib import Path
from typing import Dict, List, Tuple, Optional

class JavaPipeline:
    def __init__(self, hdl_root: str):
        self.hdl_root = Path(hdl_root)
        self.java_dir = self.hdl_root / "test_programs" / "java"
        self.temp_dir = self.hdl_root / "temp"
        self.bytecode_dir = self.temp_dir / "bytecode"
        self.jvm_dir = self.hdl_root / "AruviJVM"
        
        # Create necessary directories
        self.bytecode_dir.mkdir(parents=True, exist_ok=True)
        
    def compile_java(self, java_file: str) -> Tuple[bool, str]:
        """Compile Java source to bytecode"""
        java_path = self.java_dir / f"{java_file}.java"
        if not java_path.exists():
            return False, f"Java file not found: {java_path}"
        
        try:
            # Compile Java to bytecode
            result = subprocess.run([
                "javac", 
                "-d", str(self.bytecode_dir),
                str(java_path)
            ], capture_output=True, text=True, timeout=30)
            
            if result.returncode != 0:
                return False, f"Java compilation failed: {result.stderr}"
            
            return True, "Java compilation successful"
        except subprocess.TimeoutExpired:
            return False, "Java compilation timed out"
        except Exception as e:
            return False, f"Java compilation error: {str(e)}"
    
    def extract_bytecode(self, class_name: str, method_name: str = None) -> Tuple[bool, str, List[int]]:
        """Extract bytecode from compiled .class file"""
        class_file = self.bytecode_dir / f"{class_name}.class"
        if not class_file.exists():
            return False, f"Class file not found: {class_file}", []
        
        try:
            # Use javap to disassemble and get bytecode
            result = subprocess.run([
                "javap", "-c", "-cp", str(self.bytecode_dir), class_name
            ], capture_output=True, text=True, timeout=30)
            
            if result.returncode != 0:
                return False, f"Bytecode extraction failed: {result.stderr}", []
            
            # Parse the javap output to extract bytecode
            bytecode = self.parse_javap_output(result.stdout, method_name)
            return True, "Bytecode extraction successful", bytecode
            
        except subprocess.TimeoutExpired:
            return False, "Bytecode extraction timed out", []
        except Exception as e:
            return False, f"Bytecode extraction error: {str(e)}", []
    
    def parse_javap_output(self, javap_output: str, target_method: str = None) -> List[int]:
        """Parse javap output to extract bytecode opcodes and operands"""
        lines = javap_output.split('\n')
        bytecode = []
        in_method = False
        method_found = False
        
        for line in lines:
            line = line.strip()
            
            # Look for method start
            if target_method:
                if f"{target_method}(" in line and ("public" in line or "static" in line):
                    in_method = True
                    method_found = True
                    continue
                elif in_method and (line.startswith("public") or line.startswith("static")):
                    # New method started, stop if we were in our target method
                    if method_found:
                        break
                    in_method = False
            else:
                # If no specific method, look for any static method
                if "static" in line and "(" in line:
                    in_method = True
                    continue
            
            # Extract bytecode from method body
            if in_method and ":" in line and not line.startswith("Code:"):
                parts = line.split(":")
                if len(parts) >= 2:
                    # Parse bytecode instruction
                    instruction_part = parts[1].strip()
                    if instruction_part:
                        instruction_opcodes = self.parse_instruction_line(instruction_part)
                        bytecode.extend(instruction_opcodes)
        
        return bytecode
    
    def parse_instruction_line(self, instruction_line: str) -> List[int]:
        """Parse a single instruction line and return opcodes with operands"""
        parts = instruction_line.split()
        if not parts:
            return []
        
        instruction = parts[0]
        opcodes = []
        
        # Handle different instruction types
        if instruction == 'bipush':
            opcodes.append(16)  # bipush opcode
            if len(parts) > 1:
                try:
                    value = int(parts[1])
                    opcodes.append(value)  # The byte value to push
                except ValueError:
                    pass
        elif instruction == 'sipush':
            opcodes.append(17)  # sipush opcode
            if len(parts) > 1:
                try:
                    value = int(parts[1])
                    # sipush pushes a 16-bit value, we'll store it as 2 bytes
                    opcodes.append(value)
                except ValueError:
                    pass
        else:
            # Handle other instructions without operands
            opcode = self.map_instruction_to_opcode(instruction)
            if opcode is not None:
                opcodes.append(opcode)
        
        return opcodes
    
    def map_instruction_to_opcode(self, instruction: str) -> Optional[int]:
        """Map Java bytecode instruction to opcode number"""
        instruction = instruction.split()[0]  # Get just the instruction name
        
        # Java bytecode instruction to opcode mapping
        opcode_map = {
            'iconst_0': 3,
            'iconst_1': 4,
            'iconst_2': 5,
            'iconst_3': 6,
            'iconst_4': 7,
            'iconst_5': 8,
            'bipush': 16,
            'sipush': 17,
            'iload_0': 26,
            'iload_1': 27,
            'iload_2': 28,
            'iload_3': 29,
            'istore_0': 59,
            'istore_1': 60,
            'istore_2': 61,
            'istore_3': 62,
            'iadd': 96,
            'isub': 100,
            'imul': 104,
            'idiv': 108,
            'irem': 112,
            'return': 177,
            'ireturn': 172,
        }
        
        return opcode_map.get(instruction.lower())
    
    def create_jvm_interpreter(self, class_name: str, method_name: str, bytecode: List[int]) -> str:
        """Create a C JVM interpreter that processes the extracted bytecode"""
        
        # Convert bytecode list to C array initialization
        bytecode_array = ', '.join(map(str, bytecode))
        bytecode_size = len(bytecode)
        
        jvm_c_code = f'''/*
 * JVM Interpreter for {class_name}.{method_name}
 * Generated from Java bytecode
 */

// Hardcoded bytecode for {class_name}.{method_name}
int bytecode[] = {{{bytecode_array}}};
int bytecode_size = {bytecode_size};

// JVM state using individual variables (compatible with our C compiler)
int jvm_stack0;
int jvm_stack1;
int jvm_stack2;
int jvm_stack3;
int jvm_sp;
int jvm_local0;
int jvm_local1;
int jvm_local2;
int jvm_local3;
int jvm_pc;

// Initialize JVM
void jvm_init() {{
    jvm_sp = 0;
    jvm_pc = 0;
    jvm_stack0 = 0;
    jvm_stack1 = 0;
    jvm_stack2 = 0;
    jvm_stack3 = 0;
    jvm_local0 = 0;
    jvm_local1 = 0;
    jvm_local2 = 0;
    jvm_local3 = 0;
}}

// Push value onto operand stack
void jvm_push(int value) {{
    if (jvm_sp == 0) {{
        jvm_stack0 = value;
    }} else if (jvm_sp == 1) {{
        jvm_stack1 = value;
    }} else if (jvm_sp == 2) {{
        jvm_stack2 = value;
    }} else if (jvm_sp == 3) {{
        jvm_stack3 = value;
    }}
    jvm_sp = jvm_sp + 1;
}}

// Pop value from operand stack
int jvm_pop() {{
    jvm_sp = jvm_sp - 1;
    if (jvm_sp == 0) {{
        return jvm_stack0;
    }} else if (jvm_sp == 1) {{
        return jvm_stack1;
    }} else if (jvm_sp == 2) {{
        return jvm_stack2;
    }} else if (jvm_sp == 3) {{
        return jvm_stack3;
    }}
    return 0;
}}

// Get local variable
int jvm_get_local(int index) {{
    if (index == 0) {{
        return jvm_local0;
    }} else if (index == 1) {{
        return jvm_local1;
    }} else if (index == 2) {{
        return jvm_local2;
    }} else if (index == 3) {{
        return jvm_local3;
    }}
    return 0;
}}

// Set local variable
void jvm_set_local(int index, int value) {{
    if (index == 0) {{
        jvm_local0 = value;
    }} else if (index == 1) {{
        jvm_local1 = value;
    }} else if (index == 2) {{
        jvm_local2 = value;
    }} else if (index == 3) {{
        jvm_local3 = value;
    }}
}}

// Get bytecode instruction
int jvm_get_bytecode(int pc) {{
    if (pc >= 0 && pc < bytecode_size) {{
        return bytecode[pc];
    }}
    return 177; // RETURN if out of bounds
}}

// Execute bytecode
int jvm_execute() {{
    jvm_init();
    
    while (jvm_pc < bytecode_size) {{
        int opcode = jvm_get_bytecode(jvm_pc);
        jvm_pc = jvm_pc + 1;
        
        if (opcode == 3) {{        // OP_ICONST_0
            jvm_push(0);
        }} else if (opcode == 4) {{ // OP_ICONST_1
            jvm_push(1);
        }} else if (opcode == 5) {{ // OP_ICONST_2
            jvm_push(2);
        }} else if (opcode == 6) {{ // OP_ICONST_3
            jvm_push(3);
        }} else if (opcode == 7) {{ // OP_ICONST_4
            jvm_push(4);
        }} else if (opcode == 8) {{ // OP_ICONST_5
            jvm_push(5);
        }} else if (opcode == 16) {{ // OP_BIPUSH
            int value = jvm_get_bytecode(jvm_pc);
            jvm_pc = jvm_pc + 1;
            jvm_push(value);
        }} else if (opcode == 17) {{ // OP_SIPUSH
            int value = jvm_get_bytecode(jvm_pc);
            jvm_pc = jvm_pc + 1;
            jvm_push(value);
        }} else if (opcode == 26) {{ // OP_ILOAD_0
            jvm_push(jvm_get_local(0));
        }} else if (opcode == 27) {{ // OP_ILOAD_1
            jvm_push(jvm_get_local(1));
        }} else if (opcode == 28) {{ // OP_ILOAD_2
            jvm_push(jvm_get_local(2));
        }} else if (opcode == 29) {{ // OP_ILOAD_3
            jvm_push(jvm_get_local(3));
        }} else if (opcode == 59) {{ // OP_ISTORE_0
            jvm_set_local(0, jvm_pop());
        }} else if (opcode == 60) {{ // OP_ISTORE_1
            jvm_set_local(1, jvm_pop());
        }} else if (opcode == 61) {{ // OP_ISTORE_2
            jvm_set_local(2, jvm_pop());
        }} else if (opcode == 62) {{ // OP_ISTORE_3
            jvm_set_local(3, jvm_pop());
        }} else if (opcode == 96) {{ // OP_IADD
            int b = jvm_pop();
            int a = jvm_pop();
            jvm_push(a + b);
        }} else if (opcode == 100) {{ // OP_ISUB
            int b = jvm_pop();
            int a = jvm_pop();
            jvm_push(a - b);
        }} else if (opcode == 104) {{ // OP_IMUL
            int b = jvm_pop();
            int a = jvm_pop();
            jvm_push(a * b);
        }} else if (opcode == 108) {{ // OP_IDIV
            int b = jvm_pop();
            int a = jvm_pop();
            jvm_push(a / b);
        }} else if (opcode == 112) {{ // OP_IREM (modulo)
            int b = jvm_pop();
            int a = jvm_pop();
            jvm_push(a % b);  // Uses our MOD instruction!
        }} else if (opcode == 172) {{ // OP_IRETURN
            return jvm_pop();
        }} else if (opcode == 177) {{ // OP_RETURN
            break;
        }}
    }}
    
    // Return top of stack as result
    if (jvm_sp > 0) {{
        return jvm_pop();
    }} else {{
        return 0;
    }}
}}

int main() {{
    // Execute the Java bytecode
    int result = jvm_execute();
    
    // Return the result for verification
    return result;
}}
'''
        
        return jvm_c_code
    
    def run_complete_pipeline(self, java_file: str, method_name: str = None) -> Dict:
        """Run the complete Java-to-RISC pipeline"""
        result = {
            "java_file": java_file,
            "method_name": method_name,
            "stages": {},
            "overall_success": False,
            "final_result": None
        }
        
        print(f"🚀 Running Java-to-RISC pipeline for: {java_file}")
        
        # Stage 1: Compile Java
        print("Stage 1: Compiling Java source...")
        success, message = self.compile_java(java_file)
        result["stages"]["java_compilation"] = {"success": success, "message": message}
        if not success:
            print(f"  ❌ {message}")
            return result
        print(f"  ✅ {message}")
        
        # Stage 2: Extract bytecode
        print("Stage 2: Extracting bytecode...")
        success, message, bytecode = self.extract_bytecode(java_file, method_name)
        result["stages"]["bytecode_extraction"] = {
            "success": success, 
            "message": message, 
            "bytecode": bytecode
        }
        if not success:
            print(f"  ❌ {message}")
            return result
        print(f"  ✅ {message}")
        print(f"  📋 Extracted bytecode: {bytecode}")
        
        # Stage 3: Generate JVM interpreter
        print("Stage 3: Generating JVM interpreter...")
        jvm_code = self.create_jvm_interpreter(java_file, method_name or "main", bytecode)
        jvm_file = self.hdl_root / "test_programs" / "c" / f"java_{java_file}_jvm.c"
        
        with open(jvm_file, 'w') as f:
            f.write(jvm_code)
        
        result["stages"]["jvm_generation"] = {
            "success": True, 
            "message": "JVM interpreter generated",
            "file": str(jvm_file)
        }
        print(f"  ✅ JVM interpreter generated: {jvm_file}")
        
        # Stage 4: Compile and run on RISC processor
        print("Stage 4: Running on RISC processor...")
        try:
            # Use our existing C test runner
            proc_result = subprocess.run([
                sys.executable, "c_test_runner.py", ".", 
                "--test", f"java_{java_file}_jvm"
            ], capture_output=True, text=True, timeout=120)
            
            if proc_result.returncode == 0:
                result["stages"]["risc_execution"] = {
                    "success": True, 
                    "message": "RISC execution successful"
                }
                print(f"  ✅ RISC execution successful")
                result["overall_success"] = True
            else:
                result["stages"]["risc_execution"] = {
                    "success": False, 
                    "message": f"RISC execution failed: {proc_result.stderr}"
                }
                print(f"  ❌ RISC execution failed")
                
        except Exception as e:
            result["stages"]["risc_execution"] = {
                "success": False, 
                "message": f"RISC execution error: {str(e)}"
            }
            print(f"  ❌ RISC execution error: {str(e)}")
        
        return result

def main():
    parser = argparse.ArgumentParser(description="Java-to-RISC Execution Pipeline")
    parser.add_argument("hdl_root", help="HDL root directory path")
    parser.add_argument("--java", "-j", required=True, help="Java file name (without .java extension)")
    parser.add_argument("--method", "-m", help="Specific method to execute (default: auto-detect)")
    
    args = parser.parse_args()
    
    if not os.path.isdir(args.hdl_root):
        print(f"Error: {args.hdl_root} is not a valid directory")
        sys.exit(1)
    
    pipeline = JavaPipeline(args.hdl_root)
    result = pipeline.run_complete_pipeline(args.java, args.method)
    
    print(f"\n{'='*50}")
    if result["overall_success"]:
        print("🎉 Java-to-RISC Pipeline SUCCESSFUL!")
    else:
        print("❌ Java-to-RISC Pipeline FAILED!")
        sys.exit(1)

if __name__ == "__main__":
    main()
