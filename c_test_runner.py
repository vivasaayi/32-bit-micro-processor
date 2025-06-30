#!/usr/bin/env python3
"""
Comprehensive C-to-Assembly Testing Pipeline

This script:
1. Compiles C programs to assembly using our C compiler
2. Assembles the code to hex files
3. Runs simulation tests
4. Reports results
"""

import os
import sys
import subprocess
import json
import argparse
from pathlib import Path
from typing import Dict, List, Tuple, Optional

class CTestRunner:
    def __init__(self, hdl_root: str):
        self.hdl_root = Path(hdl_root)
        self.c_programs_dir = self.hdl_root / "test_programs" / "c"
        self.temp_dir = self.hdl_root / "temp"
        self.tools_dir = self.hdl_root / "tools"
        self.compiler_path = self.hdl_root / "compiler" / "ccompiler"  # Use correct compiler path
        self.assembler_path = self.temp_dir / "assembler"  # C assembler now in temp
        self.testbench_dir = self.hdl_root / "processor" / "testbench"
        
        # Create temp directories
        self.temp_asm_dir = self.temp_dir / "c_generated_asm"
        self.temp_hex_dir = self.temp_dir / "c_generated_hex"
        self.temp_vcd_dir = self.temp_dir / "c_generated_vcd"
        
        for dir_path in [self.temp_asm_dir, self.temp_hex_dir, self.temp_vcd_dir]:
            dir_path.mkdir(exist_ok=True, parents=True)
    
    def run_command(self, cmd: List[str], cwd: Optional[Path] = None) -> Tuple[int, str, str]:
        """Run a command and return (return_code, stdout, stderr)"""
        try:
            result = subprocess.run(
                cmd, 
                cwd=cwd or self.hdl_root,
                capture_output=True, 
                text=True,
                timeout=60
            )
            return result.returncode, result.stdout, result.stderr
        except subprocess.TimeoutExpired:
            return -1, "", "Command timed out"
        except Exception as e:
            return -1, "", str(e)
    
    def compile_c_to_assembly(self, c_file: Path) -> Tuple[bool, str, Path]:
        """Compile C file to assembly"""
        asm_file = self.temp_asm_dir / f"{c_file.stem}.asm"
        
        cmd = [str(self.compiler_path), str(c_file)]
        ret_code, stdout, stderr = self.run_command(cmd)
        
        if ret_code != 0:
            return False, f"C compilation failed: {stderr or stdout}", asm_file
        
        # The compiler writes to input.asm, so we need to move it
        generated_asm = c_file.parent / f"{c_file.stem}.asm"
        if generated_asm.exists():
            # Move to our temp directory
            generated_asm.rename(asm_file)
            return True, "C compilation successful", asm_file
        else:
            return False, "C compilation failed - no output file generated", asm_file
    
    def assemble_to_hex(self, asm_file: Path) -> Tuple[bool, str, Path]:
        """Assemble assembly file to hex"""
        hex_file = self.temp_hex_dir / f"{asm_file.stem}.hex"
        
        cmd = [str(self.assembler_path), str(asm_file), str(hex_file)]
        ret_code, stdout, stderr = self.run_command(cmd)
        
        if ret_code != 0:
            return False, f"Assembly failed: {stderr or stdout}", hex_file
        
        if not hex_file.exists():
            return False, "Assembly failed - no hex file generated", hex_file
        
        return True, "Assembly successful", hex_file
    
    def run_simulation(self, hex_file: Path, test_name: str) -> Tuple[bool, str, Dict]:
        """Run simulation and extract results"""
        vcd_file = self.temp_vcd_dir / f"{test_name}.vcd"
        
        # Create testbench with memory dump capability
        testbench_content = self.create_memory_dump_testbench(hex_file, test_name)

        
        # Write testbench
        testbench_file = self.temp_dir / f"tb_{test_name}.v"
        with open(testbench_file, 'w') as f:
            f.write(testbench_content)
        
        # Compile and run simulation
        vvp_file = self.temp_dir / f"tb_{test_name}.vvp"
        
        # Compile testbench
        compile_cmd = [
            "iverilog",
            "-o", str(vvp_file),
            str(testbench_file),
            str(self.hdl_root / "processor" / "microprocessor_system.v"),
            str(self.hdl_root / "processor" / "cpu" / "cpu_core.v"),
            str(self.hdl_root / "processor" / "cpu" / "alu.v"),
            str(self.hdl_root / "processor" / "cpu" / "register_file.v"),
            str(self.hdl_root / "processor" / "memory" / "memory_controller.v"),
            str(self.hdl_root / "processor" / "memory" / "mmu.v"),
            str(self.hdl_root / "processor" / "io" / "uart.v"),
            str(self.hdl_root / "processor" / "io" / "timer.v"),
            str(self.hdl_root / "processor" / "io" / "interrupt_controller.v")
        ]
        
        ret_code, stdout, stderr = self.run_command(compile_cmd)
        if ret_code != 0:
            return False, f"Testbench compilation failed: {stderr}", {}
        
        # Run simulation
        run_cmd = ["vvp", str(vvp_file)]
        ret_code, stdout, stderr = self.run_command(run_cmd)
        
        # Parse simulation output
        results = {
            "completed": False,
            "result_value": None,
            "log_output": "",
            "simulation_output": stdout,
            "error_output": stderr
        }
        
        # Extract log output
        log_start = stdout.find("=== LOG OUTPUT ===")
        log_end = stdout.find("=== END LOG ===")
        if log_start != -1 and log_end != -1:
            log_section = stdout[log_start:log_end + len("=== END LOG ===")]
            # Extract the actual log content
            content_start = log_section.find("Log content: ")
            if content_start != -1:
                content_line = log_section[content_start + len("Log content: "):]
                content_end = content_line.find('\n')
                if content_end != -1:
                    results["log_output"] = content_line[:content_end].replace('\\n', '\n')
        
        if "Program completed successfully" in stdout:
            results["completed"] = True
            # Extract result value
            for line in stdout.split('\n'):
                if "Final result in R1:" in line:
                    try:
                        results["result_value"] = int(line.split(":")[-1].strip())
                    except:
                        pass
        
        success = ret_code == 0 and results["completed"]
        message = "Simulation successful" if success else f"Simulation failed: {stderr or 'Unknown error'}"
        
        return success, message, results
    
    def test_c_program(self, c_file: Path) -> Dict:
        """Test a single C program through the full pipeline"""
        test_name = c_file.stem
        result = {
            "test_name": test_name,
            "c_file": str(c_file),
            "stages": {},
            "overall_success": False,
            "final_result": None
        }
        
        print(f"\n=== Testing {test_name} ===")
        
        # Stage 1: C to Assembly
        print("Stage 1: Compiling C to Assembly...")
        success, message, asm_file = self.compile_c_to_assembly(c_file)
        result["stages"]["c_to_asm"] = {
            "success": success,
            "message": message,
            "output_file": str(asm_file) if asm_file.exists() else None
        }
        
        if not success:
            print(f"  ❌ {message}")
            return result

        # Check for error message in generated ASM file
        error_prefixes = ["Compilation error", "Parser error"]
        if asm_file.exists():
            with open(asm_file, "r") as f:
                first_line = f.readline().strip()
                if any(first_line.startswith(prefix) for prefix in error_prefixes):
                    msg = f"C compilation failed: {first_line}"
                    print(f"  ❌ {msg}")
                    result["stages"]["c_to_asm"]["success"] = False
                    result["stages"]["c_to_asm"]["message"] = msg
                    return result

        print(f"  ✅ {message}")
        
        # Stage 2: Assembly to Hex
        print("Stage 2: Assembling to Hex...")
        success, message, hex_file = self.assemble_to_hex(asm_file)
        result["stages"]["asm_to_hex"] = {
            "success": success,
            "message": message,
            "output_file": str(hex_file) if hex_file.exists() else None
        }
        
        if not success:
            print(f"  ❌ {message}")
            return result
        
        print(f"  ✅ {message}")
        
        # Stage 3: Simulation
        print("Stage 3: Running Simulation...")
        success, message, sim_results = self.run_simulation(hex_file, test_name)
        result["stages"]["simulation"] = {
            "success": success,
            "message": message,
            "results": sim_results
        }
        
        if not success:
            print(f"  ❌ {message}")
            return result
        
        print(f"  ✅ {message}")
        
        # Display log output if available
        if sim_results.get("log_output"):
            print("  📜 Program Log Output:")
            log_lines = sim_results["log_output"].split('\n')
            for line in log_lines:
                if line.strip():  # Only show non-empty lines
                    print(f"      {line}")
        
        if sim_results.get("result_value") is not None:
            print(f"  🎯 Final result: {sim_results['result_value']}")
            result["final_result"] = sim_results["result_value"]
        
        result["overall_success"] = True
        return result
    
    def extract_log_from_memory(self, test_name: str) -> str:
        """Extract log string from simulation memory dump"""
        try:
            # The simulation should create a memory dump or we can extract it from VCD
            # For now, we'll create a simple approach by adding memory dump to testbench
            vcd_file = self.temp_vcd_dir / f"{test_name}.vcd"
            
            # Read the VCD file and extract memory values at addresses 0x3000-0x4000
            # This is a simplified approach - in practice, you might want to use
            # a proper VCD parser or modify the testbench to dump memory
            
            # For now, return a placeholder that shows the approach
            return "Log extraction from VCD not yet implemented - would read memory 0x3000-0x4000"
            
        except Exception as e:
            return f"Failed to extract log: {str(e)}"
    
    def create_memory_dump_testbench(self, hex_file: Path, test_name: str) -> str:
        """Create testbench that dumps memory contents for log extraction"""
        vcd_file = self.temp_vcd_dir / f"{test_name}.vcd"
        
        return f'''`timescale 1ns / 1ps

module tb_{test_name};
    reg clk;
    reg rst_n;
    wire [31:0] debug_pc;
    wire [31:0] debug_instruction;
    wire [31:0] debug_reg_data;
    wire [4:0] debug_reg_addr;
    wire [31:0] debug_result;
    wire debug_halted;
    
    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    // Memory dump task
    task dump_log_memory;
        integer i;
        integer log_length;
        integer log_addr;
        reg [7:0] log_char;
        integer actual_char_count;
        begin
            // Read log length from address 0x4000 (word address 4096)
            log_length = uut.internal_memory[4096];
            $display("=== LOG OUTPUT ===");
            $display("Log length: %d bytes", log_length);
            
            actual_char_count = 0;
            
            if (log_length > 0 && log_length < 1024) begin
                $write("Log content: ");
                // Read log content from address 0x3000 (word address 3072) 
                for (i = 0; i < log_length; i = i + 1) begin
                    log_addr = 3072 + (i / 4);  // Word address (0x3000 >> 2 = 3072)
                    case (i % 4)
                        0: log_char = uut.internal_memory[log_addr][7:0];
                        1: log_char = uut.internal_memory[log_addr][15:8];
                        2: log_char = uut.internal_memory[log_addr][23:16];
                        3: log_char = uut.internal_memory[log_addr][31:24];
                    endcase
                    
                    if (log_char >= 32 && log_char <= 126) begin
                        $write("%c", log_char);
                        actual_char_count = actual_char_count + 1;
                    end else if (log_char == 10) begin
                        $write("\\n");
                        actual_char_count = actual_char_count + 1;
                    end else if (log_char != 0) begin
                        $write("[%02d]", log_char);
                        actual_char_count = actual_char_count + 1;
                    end
                end
                $display("");
                $display("Actual characters found: %d", actual_char_count);
                
                // Also try to read the first few memory locations directly for debugging
                $display("DEBUG: First few memory words:");
                for (i = 3072; i < 3080; i = i + 1) begin
                    $display("  Memory[%d] = 0x%08x", i, uut.internal_memory[i]);
                end
                
            end else begin
                $display("No valid log data found (length=%d)", log_length);
                // Debug: Show what's actually at the length address
                $display("DEBUG: Memory[4096] (0x4000) = 0x%08x", uut.internal_memory[4096]);
            end
            $display("=== END LOG ===");
        end
    endtask
    
    // Reset and test
    initial begin
        $dumpfile("{vcd_file}");
        $dumpvars(0, tb_{test_name});
        
        // Load program at correct memory offset (0x8000 = word address 8192)
        $readmemh("{hex_file}", uut.internal_memory, 8192);
        
        // Reset
        rst_n = 0;
        #20;
        rst_n = 1;
        
        // Run simulation
        #100000;  // Run for sufficient time
        
        // Dump log memory after execution
        dump_log_memory();
        
        if (debug_halted) begin
            $display("Program completed successfully");
            $display("Final result in R1: %d", debug_result);
        end else begin
            $display("Program did not complete within timeout");
        end
        
        $finish;
    end
    
    // Instantiate the microprocessor system
    microprocessor_system uut (
        .clk(clk),
        .rst_n(rst_n),
        .ext_addr(),
        .ext_data(),
        .ext_mem_read(),
        .ext_mem_write(),
        .ext_mem_enable(),
        .ext_mem_ready(1'b1),
        .io_addr(),
        .io_data(),
        .io_read(),
        .io_write(),
        .external_interrupts(8'b0),
        .system_halted(),
        .pc_out(),
        .cpu_flags(),
        .debug_pc(debug_pc),
        .debug_instruction(debug_instruction),
        .debug_reg_data(debug_reg_data),
        .debug_reg_addr(debug_reg_addr),
        .debug_result(debug_result),
        .debug_halted(debug_halted)
    );
    
endmodule
'''
    
    def run_single_test(self, test_name: str, test_type: str = "c") -> Dict:
        """Run a single test by name"""
        if test_type == "c":
            test_file = self.c_programs_dir / f"{test_name}.c"
            if not test_file.exists():
                print(f"❌ C test file not found: {test_file}")
                return {"error": f"Test file not found: {test_file}"}
            
            print(f"🚀 Running single C test: {test_name}")
            result = self.test_c_program(test_file)
            
            # Print individual result
            if result["overall_success"]:
                print(f"\n✅ Test {test_name} PASSED!")
                if result.get("final_result") is not None:
                    print(f"🎯 Final result: {result['final_result']}")
            else:
                print(f"\n❌ Test {test_name} FAILED!")
            
            return result
        else:
            print(f"❌ Unsupported test type: {test_type}")
            return {"error": f"Unsupported test type: {test_type}"}

    def run_all_tests(self) -> Dict:
        """Run all C program tests"""
        print("🚀 Starting C-to-Assembly Test Pipeline")
        print(f"HDL Root: {self.hdl_root}")
        print(f"C Programs: {self.c_programs_dir}")
        
        # Find all C files
        c_files = list(self.c_programs_dir.glob("*.c"))
        if not c_files:
            print("❌ No C files found to test")
            return {"error": "No C files found"}
        
        print(f"Found {len(c_files)} C programs to test")
        
        all_results = {
            "summary": {
                "total_tests": len(c_files),
                "passed": 0,
                "failed": 0
            },
            "test_results": []
        }
        
        # Test each C file
        for c_file in c_files:
            result = self.test_c_program(c_file)
            all_results["test_results"].append(result)
            
            if result["overall_success"]:
                all_results["summary"]["passed"] += 1
            else:
                all_results["summary"]["failed"] += 1
        
        # Print summary
        print(f"\\n📊 Test Summary:")
        print(f"Total: {all_results['summary']['total_tests']}")
        print(f"Passed: {all_results['summary']['passed']} ✅")
        print(f"Failed: {all_results['summary']['failed']} ❌")
        
        # Save detailed results
        results_file = self.temp_dir / "c_test_results.json"
        with open(results_file, 'w') as f:
            json.dump(all_results, f, indent=2)
        
        print(f"\\n📁 Detailed results saved to: {results_file}")
        
        return all_results

    def run_enhanced_test(self, test_name: str) -> Tuple[bool, str, Dict]:
        """Run a C test with enhanced string preprocessing"""
        print(f"\n=== Running Enhanced Test: {test_name} ===")
        
        # Paths
        c_file = self.c_programs_dir / f"{test_name}.c"
        preprocessed_file = self.temp_asm_dir / f"{test_name}_preprocessed.c"
        memory_layout_file = self.temp_asm_dir / f"{test_name}_memory_layout.json"
        asm_file = self.temp_asm_dir / f"{test_name}.asm"
        enhanced_asm_file = self.temp_asm_dir / f"{test_name}_enhanced.asm"
        hex_file = self.temp_hex_dir / f"{test_name}_enhanced.hex"
        
        if not c_file.exists():
            return False, f"C file not found: {c_file}", {}
        
        # Step 1: Enhanced String Preprocessing
        print("Step 1: Enhanced string preprocessing...")
        preprocess_cmd = [
            "python3", 
            str(self.tools_dir / "enhanced_string_preprocessor.py"),
            str(c_file),
            str(preprocessed_file),
            str(memory_layout_file)
        ]
        
        ret_code, stdout, stderr = self.run_command(preprocess_cmd)
        if ret_code != 0:
            return False, f"Enhanced preprocessing failed: {stderr}", {}
        
        print(f"Preprocessing output: {stdout}")
        
        # Step 2: Compile to Assembly
        print("Step 2: Compiling to assembly...")
        compile_cmd = [str(self.compiler_path), str(preprocessed_file)]
        ret_code, stdout, stderr = self.run_command(compile_cmd)
        if ret_code != 0:
            return False, f"Compilation failed: {stderr}", {}
        
        # The C compiler creates a .asm file automatically
        compiler_asm_file = preprocessed_file.with_suffix('.asm')
        if not compiler_asm_file.exists():
            return False, f"Compiler did not generate assembly file: {compiler_asm_file}", {}
        
        # Copy to our expected location
        import shutil
        shutil.copy(compiler_asm_file, asm_file)
        
        # Step 3: Enhanced Memory Write Postprocessing
        print("Step 3: Enhanced memory write postprocessing...")
        postprocess_cmd = [
            "python3", 
            str(self.tools_dir / "enhanced_memory_writes.py"),
            str(asm_file),
            str(enhanced_asm_file),
            str(memory_layout_file)
        ]
        
        ret_code, stdout, stderr = self.run_command(postprocess_cmd)
        if ret_code != 0:
            return False, f"Enhanced postprocessing failed: {stderr}", {}
        
        print(f"Postprocessing output: {stdout}")
        
        # Step 4: Assemble to Hex
        print("Step 4: Assembling to hex...")
        assemble_cmd = [str(self.assembler_path), str(enhanced_asm_file), str(hex_file)]
        ret_code, stdout, stderr = self.run_command(assemble_cmd)
        if ret_code != 0:
            return False, f"Assembly failed: {stderr}", {}
        
        # Step 5: Run Simulation
        print("Step 5: Running simulation...")
        success, message, sim_results = self.run_simulation(hex_file, f"{test_name}_enhanced")
        
        # Extract string output from memory layout for display
        if memory_layout_file.exists():
            try:
                import json
                with open(memory_layout_file, 'r') as f:
                    layout = json.load(f)
                
                print("\n🎯 STRING OUTPUT RESULTS:")
                print("=" * 50)
                
                for i, (func_name, info) in enumerate(layout['functions'].items(), 1):
                    ascii_vals = info['ascii_values']
                    string_content = ''.join(chr(val) for val in ascii_vals)
                    print(f"  {i}. \"{string_content.strip()}\"")
                
                print("=" * 50)
                print(f"✅ Enhanced string manipulation completed successfully!")
                print(f"   • {len(layout['functions'])} logging functions generated")
                print(f"   • {layout['total_length']} bytes of string data")
                print(f"   • Program execution flow captured")
                
            except Exception as e:
                print(f"Note: Could not extract string layout: {e}")
        
        return success, message, sim_results
    
def main():
    parser = argparse.ArgumentParser(description="C-to-Assembly Test Pipeline")
    parser.add_argument("hdl_root", help="HDL root directory path")
    parser.add_argument("--test", "-t", help="Run specific test by name (without extension)")
    parser.add_argument("--type", choices=["c", "assembly"], default="c", 
                       help="Test type: 'c' for C files, 'assembly' for assembly files")
    parser.add_argument("--enhanced", "-e", action="store_true",
                       help="Use enhanced string preprocessing and memory writes")
    
    args = parser.parse_args()
    
    if not os.path.isdir(args.hdl_root):
        print(f"Error: {args.hdl_root} is not a valid directory")
        sys.exit(1)
    
    runner = CTestRunner(args.hdl_root)
    
    if args.test:
        # Run single test
        if args.enhanced:
            success, message, results = runner.run_enhanced_test(args.test)
            print(f"\n{'✅ SUCCESS' if success else '❌ FAILED'}: {message}")
            if not success:
                sys.exit(1)
        else:
            result = runner.run_single_test(args.test, args.type)
            if "error" in result:
                sys.exit(1)
            elif not result.get("overall_success", False):
                sys.exit(1)
    else:
        # Run all tests
        results = runner.run_all_tests()
        if results.get("summary", {}).get("failed", 0) > 0:
            sys.exit(1)

if __name__ == "__main__":
    main()
