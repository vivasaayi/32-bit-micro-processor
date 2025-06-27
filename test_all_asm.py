#!/usr/bin/env python3
"""
Comprehensive 32-bit ASM Test Runner
Runs all ASM files in the examples directory and generates testbenches
All temporary files are organized in a temp directory
"""

import os
import sys
import subprocess
import glob
import shutil
from pathlib import Path
import time

class ASMTestRunner32:
    def __init__(self, workspace_dir="."):
        self.workspace_dir = Path(workspace_dir).resolve()
        self.temp_dir = self.workspace_dir / "temp"
        self.examples_dir = self.workspace_dir / "examples"
        self.testbench_dir = self.workspace_dir / "testbench"
        self.tools_dir = self.workspace_dir / "tools"
        self.assembler = self.tools_dir / "assembler.py"
        
        # Create temp directory structure
        self.temp_dir.mkdir(exist_ok=True)
        (self.temp_dir / "hex").mkdir(exist_ok=True)
        (self.temp_dir / "testbenches").mkdir(exist_ok=True)
        (self.temp_dir / "vvp").mkdir(exist_ok=True)
        (self.temp_dir / "vcd").mkdir(exist_ok=True)
        (self.temp_dir / "reports").mkdir(exist_ok=True)
        
        # Expected results for each 32-bit test program
        self.test_expectations = {
            "simple_test.asm": {
                "registers": {
                    "R0": 42000,   # 0x0000A410
                    "R1": 10000,   # 0x00002710
                    "R2": 52000,   # 0x0000CB20
                    "R3": 1000,    # 0x000003E8
                    "R4": 51000,   # 0x0000C738
                    "R5": 52000    # 0x0000CB20 (from memory)
                },
                "memory_check": {"start": 0x2000, "expected": [52000]},
                "description": "Basic 32-bit arithmetic: Addition, subtraction, memory load/store",
                "halt_expected": True
            },
            "comprehensive_test.asm": {
                "registers": {
                    "R0": 100000,   # 0x000186A0
                    "R1": 50000,    # 0x0000C350
                    "R2": 150000,   # 0x000249F0
                    "R11": 150000,  # from memory
                    "R12": 1200000, # from memory
                    "R13": 155000,  # R11 + 5000
                    "R14": 1190000  # R12 - 10000
                },
                "memory_check": {"start": 0x3000, "expected": [150000, 1200000]},
                "description": "Comprehensive 32-bit test: arithmetic, logic, memory, immediate ops",
                "halt_expected": True
            },
            "bubble_sort.asm": {
                "memory_check": {"start": 0x5000, "expected": [50000, 100000, 300000, 750000]},
                "description": "32-bit bubble sort - 4 elements: demonstrates sorting with 32-bit values",
                "halt_expected": True
            },
            "simple_sort.asm": {
                "memory_check": {"start": 0x1000, "expected": [10000, 30000, 50000, 80000]},
                "description": "32-bit simple sort - 4 elements from main test program",
                "halt_expected": True
            },
            "advanced_test.asm": {
                "registers": {
                    "R0": 5,      # counter final value
                    "R2": 15      # sum = 0+1+2+3+4 = 10, then *3 = 30, then /2 = 15
                },
                "memory_check": {"start": 0x4000, "expected": [15]},
                "description": "Advanced 32-bit test with loops and complex arithmetic",
                "halt_expected": True
            },
            "hello_world.asm": {
                "description": "32-bit Hello world output test - demonstrates I/O and string handling",
                "halt_expected": True
            },
            "mini_os.asm": {
                "memory_check": {"start": 0x5100, "expected": [300000]},
                "description": "32-bit mini OS kernel test - basic process and system call handling",
                "halt_expected": True
            },
            "sort_demo.asm": {
                "memory_check": {"start": 0x1250, "expected": [100000, 120000, 1890000, 2550000]},
                "description": "32-bit sorting demo - 4 elements scaled up demonstration",
                "halt_expected": True
            },
            "bubble_sort_real.asm": {
                "memory_check": {"start": 0x8200, "expected": [70000, 180000, 350000, 730000, 1260000, 1420000, 2010000, 2390000]},
                "description": "Real 32-bit bubble sort - 8 elements: comprehensive sorting algorithm",
                "halt_expected": True
            },
            "simple_sort_new.asm": {
                "memory_check": {"start": 0x8200, "expected": [140000, 270000, 380000, 650000, 810000, 930000]},
                "description": "Enhanced 32-bit simple sort - 6 elements fully expanded algorithm",
                "halt_expected": True
            },
            # Default expectations for other programs
            "default": {
                "description": "Basic 32-bit execution test - check for completion",
                "halt_expected": True
            }
        }
        
        self.results = []
        
    def get_asm_files(self):
        """Get all ASM files from examples directory"""
        asm_files = list(self.examples_dir.glob("*.asm"))
        return sorted(asm_files)
        
    def assemble_file(self, asm_file):
        """Assemble ASM file to HEX"""
        print(f"Assembling {asm_file.name}...")
        hex_file = self.temp_dir / "hex" / f"{asm_file.stem}.hex"
        
        try:
            cmd = [sys.executable, str(self.assembler), str(asm_file), str(hex_file)]
            result = subprocess.run(cmd, capture_output=True, text=True, cwd=self.workspace_dir)
            
            if result.returncode == 0:
                print(f"  ✓ Generated {hex_file.name}")
                return hex_file, None
            else:
                error = result.stderr or result.stdout or "Assembly failed"
                print(f"  ✗ Assembly failed: {error}")
                return None, error
        except Exception as e:
            error = f"Exception during assembly: {e}"
            print(f"  ✗ {error}")
            return None, error
        
    def generate_testbench(self, asm_file, hex_file):
        """Generate testbench for ASM file"""
        print(f"Generating testbench for {asm_file.name}...")
        
        # Get test expectations for this ASM file
        expectations = self.test_expectations.get(asm_file.name, self.test_expectations["default"])
        
        testbench_file = self.temp_dir / "testbenches" / f"tb_{asm_file.stem}.v"
        
        # Generate testbench content
        testbench_content = f'''`timescale 1ns / 1ps

module tb_{asm_file.stem};
    // Clock and reset
    reg clk;
    reg rst_n;
    
    // Test control
    reg test_passed;
    reg test_completed;
    integer cycle_count;
    integer max_cycles = 10000;
    
    // System interface
    wire [31:0] ext_addr;
    wire [31:0] ext_data;
    wire ext_mem_read, ext_mem_write;
    wire system_halted;
    wire [31:0] pc_out;
    
    // Instantiate the 32-bit microprocessor system
    microprocessor_system uut (
        .clk(clk),
        .rst_n(rst_n),
        .ext_addr(ext_addr),
        .ext_data(ext_data),
        .ext_mem_read(ext_mem_read),
        .ext_mem_write(ext_mem_write),
        .ext_mem_ready(1'b1),
        .external_interrupts(8'h00),
        .system_halted(system_halted),
        .pc_out(pc_out)
    );
    
    // Clock generation - 100MHz
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    // Test sequence
    initial begin
        $dumpfile("temp/vcd/tb_{asm_file.stem}.vcd");
        $dumpvars(0, tb_{asm_file.stem});
        
        // Initialize
        test_passed = 1'b0;
        test_completed = 1'b0;
        cycle_count = 0;
        
        // Load program into memory
        $readmemh("temp/hex/{asm_file.stem}.hex", uut.internal_memory);
        
        // Reset sequence
        rst_n = 0;
        #100;
        rst_n = 1;
        
        $display("=== 32-BIT TEST: {asm_file.name} ===");
        $display("Description: {expectations['description']}");
        $display("Starting program execution...");
        
        // Wait for completion or timeout
        while (!system_halted && cycle_count < max_cycles) begin
            @(posedge clk);
            cycle_count = cycle_count + 1;
            
            // Progress indicator
            if (cycle_count % 1000 == 0) begin
                $display("Cycle %6d: PC = 0x%08x", cycle_count, pc_out);
            end
        end
        
        if (system_halted) begin
            $display("Program completed successfully at cycle %6d", cycle_count);
            $display("Final PC: 0x%08x", pc_out);
            test_completed = 1'b1;
            test_passed = 1'b1;
            
            // Check results based on expectations
            $display("\\n=== Checking Results ===");'''

        # Add memory checks if specified
        if "memory_check" in expectations:
            mem_check = expectations["memory_check"]
            start_addr = mem_check["start"]
            expected_values = mem_check["expected"]
            
            testbench_content += f'''
            // Check memory contents
            $display("Memory contents:");'''
            
            for i, expected_val in enumerate(expected_values):
                addr = start_addr + (i * 4)  # 32-bit addressing
                word_addr = addr // 4
                testbench_content += f'''
            $display("Memory[0x{addr:04X}] = %d (should be {expected_val})", uut.internal_memory[{word_addr}]);'''
            
            testbench_content += f'''
            // Verify memory contents
            if ('''
            
            conditions = []
            for i, expected_val in enumerate(expected_values):
                addr = start_addr + (i * 4)
                word_addr = addr // 4
                conditions.append(f"uut.internal_memory[{word_addr}] == 32'd{expected_val}")
            
            testbench_content += " &&\n                ".join(conditions)
            testbench_content += f''') begin
                $display("\\n✓ MEMORY TEST PASSED - Values correctly stored!");
            end else begin
                $display("\\n✗ MEMORY TEST FAILED - Incorrect values in memory");
                test_passed = 1'b0;
            end'''

        testbench_content += f'''
            if (test_passed) begin
                $display("\\n✓ {asm_file.stem.upper()} Test PASSED");
            end else begin
                $display("\\n✗ {asm_file.stem.upper()} Test FAILED");
            end
        end else begin
            $display("✗ Test FAILED - Program did not complete within %d cycles", max_cycles);
            test_passed = 1'b0;
        end
        
        $display("\\nTest completed.");
        $finish;
    end
    
endmodule'''
        
        # Write testbench file
        with open(testbench_file, 'w') as f:
            f.write(testbench_content)
        
        print(f"  ✓ Generated {testbench_file.name}")
        return testbench_file
        
    def compile_testbench(self, testbench_file, asm_file):
        """Compile testbench with iverilog"""
        print(f"Compiling testbench for {asm_file.name}...")
        
        vvp_file = self.temp_dir / "vvp" / f"tb_{asm_file.stem}.vvp"
        
        # Source files for compilation
        source_files = [
            self.workspace_dir / "cpu" / "cpu_core.v",
            self.workspace_dir / "cpu" / "alu.v", 
            self.workspace_dir / "cpu" / "register_file.v",
            self.workspace_dir / "microprocessor_system.v",
            testbench_file
        ]
        
        cmd = ["iverilog", "-o", str(vvp_file)] + [str(f) for f in source_files]
        
        try:
            result = subprocess.run(cmd, capture_output=True, text=True, cwd=self.workspace_dir)
            
            if result.returncode == 0:
                print(f"  ✓ Compiled {vvp_file.name}")
                return vvp_file, None
            else:
                error = result.stderr or "Compilation failed"
                print(f"  ✗ Compilation failed: {error}")
                return None, error
        except Exception as e:
            error = f"Exception during compilation: {e}"
            print(f"  ✗ {error}")
            return None, error
        
    def run_simulation(self, vvp_file, asm_file):
        """Run simulation with vvp"""
        print(f"Running simulation for {asm_file.name}...")
        
        report_file = self.temp_dir / "reports" / f"{asm_file.stem}_report.txt"
        
        cmd = ["vvp", str(vvp_file)]
        
        try:
            result = subprocess.run(cmd, capture_output=True, text=True,
                                   cwd=self.workspace_dir, timeout=30)
            
            # Write report
            with open(report_file, 'w') as f:
                f.write(f"Simulation Report for {asm_file.name}\n")
                f.write("=" * 50 + "\n")
                f.write(f"Return code: {result.returncode}\n")
                f.write(f"STDOUT:\n{result.stdout}\n")
                if result.stderr:
                    f.write(f"STDERR:\n{result.stderr}\n")
            
            if result.returncode == 0:
                print(f"  ✓ Simulation completed")
                # Parse results from output
                passed = "Test PASSED" in result.stdout
                return passed, result.stdout, None
            else:
                error = result.stderr or "Simulation failed"
                print(f"  ✗ Simulation failed: {error}")
                return False, result.stdout, error
                
        except subprocess.TimeoutExpired:
            error = "Simulation timeout (30s)"
            print(f"  ✗ {error}")
            return False, "", error
        except Exception as e:
            error = f"Exception during simulation: {e}"
            print(f"  ✗ {error}")
            return False, "", error
        
    def run_single_test(self, asm_file):
        """Run complete test for a single ASM file"""
        print(f"\n{'='*60}")
        print(f"Testing: {asm_file.name}")
        print('='*60)
        
        result = {
            "file": asm_file.name,
            "passed": False,
            "errors": [],
            "output": ""
        }
        
        # Step 1: Assemble
        hex_file, error = self.assemble_file(asm_file)
        if error:
            result["errors"].append(f"Assembly: {error}")
            return result
        
        # Step 2: Generate testbench
        try:
            testbench_file = self.generate_testbench(asm_file, hex_file)
        except Exception as e:
            result["errors"].append(f"Testbench generation: {e}")
            return result
        
        # Step 3: Compile
        vvp_file, error = self.compile_testbench(testbench_file, asm_file)
        if error:
            result["errors"].append(f"Compilation: {error}")
            return result
        
        # Step 4: Simulate
        passed, output, error = self.run_simulation(vvp_file, asm_file)
        result["output"] = output
        if error:
            result["errors"].append(f"Simulation: {error}")
        
        result["passed"] = passed and len(result["errors"]) == 0
        return result
        
    def run_all_tests(self):
        """Run all tests and generate summary"""
        print("32-Bit ASM Test Runner")
        print("=" * 60)
        print(f"Workspace: {self.workspace_dir}")
        print(f"Examples: {self.examples_dir}")
        print(f"Temp dir: {self.temp_dir}")
        
        asm_files = self.get_asm_files()
        print(f"\nFound {len(asm_files)} ASM files:")
        for f in asm_files:
            print(f"  - {f.name}")
        
        if not asm_files:
            print("No ASM files found!")
            return
        
        # Run tests
        start_time = time.time()
        
        for asm_file in asm_files:
            result = self.run_single_test(asm_file)
            self.results.append(result)
        
        elapsed_time = time.time() - start_time
        
        # Generate summary
        self.generate_summary(elapsed_time)
        
    def generate_summary(self, elapsed_time):
        """Generate test summary"""
        print(f"\n{'='*60}")
        print("TEST SUMMARY")
        print('='*60)
        
        passed_count = sum(1 for r in self.results if r["passed"])
        total_count = len(self.results)
        
        print(f"Total tests: {total_count}")
        print(f"Passed: {passed_count}")
        print(f"Failed: {total_count - passed_count}")
        print(f"Success rate: {passed_count/total_count*100:.1f}%")
        print(f"Elapsed time: {elapsed_time:.2f} seconds")
        
        print(f"\nDetailed Results:")
        for result in self.results:
            status = "✓ PASS" if result["passed"] else "✗ FAIL"
            print(f"  {status} {result['file']}")
            for error in result["errors"]:
                print(f"    Error: {error}")
        
        # Write summary to file
        summary_file = self.temp_dir / "reports" / "test_summary.txt"
        with open(summary_file, 'w') as f:
            f.write("32-Bit ASM Test Summary\n")
            f.write("=" * 30 + "\n")
            f.write(f"Total tests: {total_count}\n")
            f.write(f"Passed: {passed_count}\n")
            f.write(f"Failed: {total_count - passed_count}\n")
            f.write(f"Success rate: {passed_count/total_count*100:.1f}%\n")
            f.write(f"Elapsed time: {elapsed_time:.2f} seconds\n\n")
            
            for result in self.results:
                f.write(f"{'PASS' if result['passed'] else 'FAIL'}: {result['file']}\n")
                for error in result["errors"]:
                    f.write(f"  Error: {error}\n")
                f.write("\n")
        
        print(f"\nSummary written to: {summary_file}")
        print(f"All test files available in: {self.temp_dir}")

def main():
    if len(sys.argv) > 1:
        workspace_dir = sys.argv[1]
    else:
        workspace_dir = "."
    
    runner = ASMTestRunner32(workspace_dir)
    runner.run_all_tests()

if __name__ == "__main__":
    main()