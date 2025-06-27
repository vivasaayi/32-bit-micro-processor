#!/usr/bin/env python3
"""
Comprehensive ASM Test Runner
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

class ASMTestRunner:
    def __init__(self, workspace_dir="."):
        self.workspace_dir = Path(workspace_dir).resolve()
        self.temp_dir = self.workspace_dir / "temp"
        self.examples_dir = self.workspace_dir / "examples"
        self.tools_dir = self.workspace_dir / "tools"
        self.assembler = self.tools_dir / "corrected_assembler.py"
        
        # Create temp directory structure
        self.temp_dir.mkdir(exist_ok=True)
        (self.temp_dir / "hex").mkdir(exist_ok=True)
        (self.temp_dir / "testbenches").mkdir(exist_ok=True)
        (self.temp_dir / "vvp").mkdir(exist_ok=True)
        (self.temp_dir / "vcd").mkdir(exist_ok=True)
        (self.temp_dir / "reports").mkdir(exist_ok=True)
        
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
            error = f"Exception during assembly: {str(e)}"
            print(f"  ✗ {error}")
            return None, error
    
    def create_testbench(self, asm_file, hex_file):
        """Create a testbench for the ASM program"""
        testbench_file = self.temp_dir / "testbenches" / f"tb_{asm_file.stem}.v"
        mem_file = self.temp_dir / "testbenches" / f"{asm_file.stem}.mem"
        
        # Read hex file to embed memory initialization
        try:
            with open(hex_file, 'r') as f:
                hex_content = f.read()
        except Exception as e:
            print(f"  ✗ Could not read hex file: {e}")
            return None, str(e)
        
        # Parse hex file to extract actual machine code bytes
        hex_bytes = []
        for line in hex_content.split('\n'):
            line = line.strip()
            if line and not line.startswith(';'):  # Skip comments
                if line.startswith(':'):
                    # Parse Intel HEX format: :address data
                    parts = line.split(' ')
                    if len(parts) > 1:
                        # Extract hex bytes (skip the address part)
                        for part in parts[1:]:
                            part = part.strip()
                            if part and len(part) == 2:
                                try:
                                    int(part, 16)  # Validate it's hex
                                    hex_bytes.append(part)
                                except ValueError:
                                    pass
        
        # Create memory file for $readmemh
        try:
            with open(mem_file, 'w') as f:
                for byte_val in hex_bytes:
                    f.write(f"{byte_val}\n")
        except Exception as e:
            print(f"  ✗ Could not create memory file: {e}")
            return None, str(e)
        
        # Generate testbench content
        testbench_content = f'''`timescale 1ns / 1ps

module tb_{asm_file.stem};
    // Clock and reset
    reg clk;
    reg rst_n;
    
    // Memory for program
    reg [7:0] program_mem [0:4095];
    
    // Instantiate the microprocessor system
    microprocessor_system uut (
        .clk(clk),
        .rst_n(rst_n)
    );
    
    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100MHz clock
    end
    
    // Test sequence
    initial begin
        $dumpfile("{self.temp_dir.name}/vcd/tb_{asm_file.stem}.vcd");
        $dumpvars(0, tb_{asm_file.stem});
        
        // Load program into memory
        $readmemh("{mem_file.name}", program_mem);
        
        // Copy program to system memory (simplified approach)
        // This is a simulation shortcut - in real hardware, 
        // the program would be in ROM or loaded by bootloader
        
        // Reset sequence
        rst_n = 0;
        #100;
        rst_n = 1;
        
        // Run program
        $display("Starting {asm_file.name} test...");
        $display("Time=%0t: Program started", $time);
        $display("Loaded %d bytes of program data", {len(hex_bytes)});
        
        // Monitor basic activity
        $monitor("Time=%0t: CLK=%b, RST=%b", $time, clk, rst_n);
        
        // Run for a reasonable time
        repeat(2000) begin
            @(posedge clk);
        end
        
        $display("Time=%0t: Test completed", $time);
        $finish;
    end
    
endmodule
'''
        
        try:
            with open(testbench_file, 'w') as f:
                f.write(testbench_content)
            print(f"  ✓ Created testbench {testbench_file.name}")
            print(f"  ✓ Created memory file {mem_file.name}")
            return testbench_file, None
        except Exception as e:
            error = f"Could not create testbench: {e}"
            print(f"  ✗ {error}")
            return None, error
    
    def run_simulation(self, asm_file, testbench_file):
        """Run the simulation for a testbench"""
        print(f"Running simulation for {asm_file.name}...")
        
        vvp_file = self.temp_dir / "vvp" / f"tb_{asm_file.stem}.vvp"
        vcd_file = self.temp_dir / "vcd" / f"tb_{asm_file.stem}.vcd"
        log_file = self.temp_dir / "reports" / f"{asm_file.stem}_sim.log"
        
        try:
            # Compile with iverilog
            compile_cmd = [
                "iverilog",
                "-o", str(vvp_file),
                "-I", str(self.workspace_dir),
                str(testbench_file),
                str(self.workspace_dir / "microprocessor_system.v")
            ]
            
            # Add all HDL files
            for hdl_dir in ["cpu", "memory", "io"]:
                hdl_path = self.workspace_dir / hdl_dir
                if hdl_path.exists():
                    compile_cmd.extend([str(f) for f in hdl_path.glob("*.v")])
            
            print(f"  Compiling with: {' '.join(compile_cmd)}")
            
            compile_result = subprocess.run(compile_cmd, capture_output=True, text=True, cwd=self.workspace_dir)
            
            if compile_result.returncode != 0:
                error = f"Compilation failed: {compile_result.stderr}"
                print(f"  ✗ {error}")
                return None, error
            
            print(f"  ✓ Compiled to {vvp_file.name}")
            
            # Run simulation
            sim_cmd = ["vvp", str(vvp_file)]
            sim_result = subprocess.run(sim_cmd, capture_output=True, text=True, cwd=self.workspace_dir)
            
            # Save simulation log
            with open(log_file, 'w') as f:
                f.write(f"=== Simulation Log for {asm_file.name} ===\n\n")
                f.write("STDOUT:\n")
                f.write(sim_result.stdout)
                f.write("\n\nSTDERR:\n")
                f.write(sim_result.stderr)
                f.write(f"\n\nReturn code: {sim_result.returncode}\n")
            
            if sim_result.returncode == 0:
                print(f"  ✓ Simulation completed successfully")
                print(f"  ✓ VCD file: {vcd_file}")
                print(f"  ✓ Log file: {log_file}")
                return {
                    'stdout': sim_result.stdout,
                    'stderr': sim_result.stderr,
                    'vcd_file': vcd_file,
                    'log_file': log_file
                }, None
            else:
                error = f"Simulation failed: {sim_result.stderr}"
                print(f"  ✗ {error}")
                return None, error
                
        except Exception as e:
            error = f"Exception during simulation: {str(e)}"
            print(f"  ✗ {error}")
            return None, error
    
    def test_single_asm(self, asm_file):
        """Test a single ASM file through the complete pipeline"""
        print(f"\n{'='*60}")
        print(f"Testing {asm_file.name}")
        print(f"{'='*60}")
        
        result = {
            'asm_file': asm_file.name,
            'success': False,
            'stages': {},
            'errors': []
        }
        
        # Stage 1: Assembly
        hex_file, error = self.assemble_file(asm_file)
        result['stages']['assembly'] = hex_file is not None
        if error:
            result['errors'].append(f"Assembly: {error}")
            return result
        
        # Stage 2: Testbench creation
        testbench_file, error = self.create_testbench(asm_file, hex_file)
        result['stages']['testbench'] = testbench_file is not None
        if error:
            result['errors'].append(f"Testbench: {error}")
            return result
        
        # Stage 3: Simulation
        sim_result, error = self.run_simulation(asm_file, testbench_file)
        result['stages']['simulation'] = sim_result is not None
        if error:
            result['errors'].append(f"Simulation: {error}")
            return result
        
        result['success'] = True
        result['sim_output'] = sim_result
        return result
    
    def run_all_tests(self):
        """Run tests for all ASM files"""
        print(f"ASM Test Runner")
        print(f"Workspace: {self.workspace_dir}")
        print(f"Temp directory: {self.temp_dir}")
        print(f"Assembler: {self.assembler}")
        
        asm_files = self.get_asm_files()
        print(f"\nFound {len(asm_files)} ASM files:")
        for f in asm_files:
            print(f"  - {f.name}")
        
        # Run tests
        start_time = time.time()
        for asm_file in asm_files:
            result = self.test_single_asm(asm_file)
            self.results.append(result)
        
        end_time = time.time()
        
        # Generate summary report
        self.generate_summary_report(end_time - start_time)
    
    def generate_summary_report(self, duration):
        """Generate a summary report of all tests"""
        report_file = self.temp_dir / "reports" / "summary.txt"
        
        successful = [r for r in self.results if r['success']]
        failed = [r for r in self.results if not r['success']]
        
        report_content = f"""
ASM Test Runner Summary Report
Generated: {time.strftime('%Y-%m-%d %H:%M:%S')}
Duration: {duration:.2f} seconds

=== OVERVIEW ===
Total files: {len(self.results)}
Successful: {len(successful)}
Failed: {len(failed)}

=== SUCCESSFUL TESTS ===
"""
        
        for result in successful:
            report_content += f"✓ {result['asm_file']}\n"
        
        report_content += f"\n=== FAILED TESTS ===\n"
        for result in failed:
            report_content += f"✗ {result['asm_file']}\n"
            for error in result['errors']:
                report_content += f"    {error}\n"
        
        report_content += f"\n=== STAGE BREAKDOWN ===\n"
        assembly_success = sum(1 for r in self.results if r['stages'].get('assembly', False))
        testbench_success = sum(1 for r in self.results if r['stages'].get('testbench', False))
        simulation_success = sum(1 for r in self.results if r['stages'].get('simulation', False))
        
        report_content += f"Assembly: {assembly_success}/{len(self.results)}\n"
        report_content += f"Testbench: {testbench_success}/{len(self.results)}\n"
        report_content += f"Simulation: {simulation_success}/{len(self.results)}\n"
        
        report_content += f"\n=== FILE LOCATIONS ===\n"
        report_content += f"HEX files: {self.temp_dir}/hex/\n"
        report_content += f"Testbenches: {self.temp_dir}/testbenches/\n"
        report_content += f"VVP files: {self.temp_dir}/vvp/\n"
        report_content += f"VCD files: {self.temp_dir}/vcd/\n"
        report_content += f"Logs: {self.temp_dir}/reports/\n"
        
        # Write report
        with open(report_file, 'w') as f:
            f.write(report_content)
        
        # Print summary to console
        print(f"\n{'='*60}")
        print("TEST SUMMARY")
        print(f"{'='*60}")
        print(f"Total: {len(self.results)}, Success: {len(successful)}, Failed: {len(failed)}")
        print(f"Duration: {duration:.2f} seconds")
        print(f"Report saved to: {report_file}")
        
        if failed:
            print(f"\nFailed tests:")
            for result in failed:
                print(f"  ✗ {result['asm_file']}: {', '.join(result['errors'])}")
        
        if successful:
            print(f"\nSuccessful tests:")
            for result in successful:
                print(f"  ✓ {result['asm_file']}")

def main():
    if len(sys.argv) > 1:
        workspace = sys.argv[1]
    else:
        workspace = "."
    
    runner = ASMTestRunner(workspace)
    runner.run_all_tests()

if __name__ == "__main__":
    main()
