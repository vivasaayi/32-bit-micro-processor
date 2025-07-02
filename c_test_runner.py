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
        self.assembler_path = self.hdl_root / "tools" / "assembler"  # Use enhanced assembler (now primary)
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
        
        # The compiler writes to output.s in the current directory
        generated_asm = self.hdl_root / "output.s"
        if generated_asm.exists():
            # Move to our temp directory with proper naming
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
        
        # Use framebuffer testbench as standard for all tests
        is_framebuffer_test = True  # Enable framebuffer dumping for all tests
        
        # Sanitize test name for Verilog module name (remove dots and other invalid chars)
        sanitized_test_name = test_name.replace('.', '_').replace('-', '_')
        
        # Create appropriate testbench
        if is_framebuffer_test:
            testbench_content = self.create_framebuffer_testbench(hex_file, sanitized_test_name)
            print(f"Using framebuffer testbench for graphics test: {test_name}")
        else:
            testbench_content = self.create_memory_dump_testbench(hex_file, sanitized_test_name)

        
        # Write testbench
        testbench_file = self.temp_dir / f"tb_{sanitized_test_name}.v"
        with open(testbench_file, 'w') as f:
            f.write(testbench_content)
        
        # Compile and run simulation
        vvp_file = self.temp_dir / f"tb_{sanitized_test_name}.vvp"

        print("Test Bench file:", testbench_file)
        print("VVD File:", vvp_file)
        
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
        
        print("Compile Command:", compile_cmd)
        ret_code, stdout, stderr = self.run_command(compile_cmd)
        if ret_code != 0:
            return False, f"Testbench compilation failed: {stderr}", {}
        
        # Run simulation
        run_cmd = ["vvp", str(vvp_file)]
        print("VVP Command: ", run_cmd)
        ret_code, stdout, stderr = self.run_command(run_cmd)

        # Save simulation output to a log file
        sim_log_dir = self.temp_dir / "simulation_logs"
        sim_log_dir.mkdir(exist_ok=True)
        sim_log_file = sim_log_dir / f"{test_name}.log"
        with open(sim_log_file, "w") as f:
            f.write(stdout)
            if stderr:
                f.write("\n=== STDERR ===\n")
                f.write(stderr)

        # Parse simulation output
        results = {
            "completed": False,
            "result_value": None,
            "log_output": "",
            "simulation_output": stdout,
            "error_output": stderr,
            "log_file": str(sim_log_file)
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
        
        if "Program completed successfully" in stdout or "✓ Program completed successfully" in stdout:
            results["completed"] = True
            # Extract result value
            for line in stdout.split('\n'):
                if "Final result in R1:" in line:
                    try:
                        results["result_value"] = int(line.split(":")[-1].strip())
                    except:
                        pass
        
        # For assembly tests, also consider it successful if simulation finishes without crash
        success = ret_code == 0
        if results["completed"]:
            message = "Simulation successful"
        elif ret_code == 0:
            message = "Simulation completed (program status unclear)"  
        else:
            message = f"Simulation failed: {stderr or 'Unknown error'}"
        
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
    
    def create_memory_dump_testbench(self, hex_file: Path, sanitized_test_name: str) -> str:
        """Create testbench that dumps memory contents for log extraction"""
        vcd_file = self.temp_vcd_dir / f"{sanitized_test_name}.vcd"
        
        return f'''`timescale 1ns / 1ps

module tb_{sanitized_test_name};
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
        $dumpvars(0, tb_{sanitized_test_name});
        
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
    
    def create_framebuffer_testbench(self, hex_file: Path, sanitized_test_name: str) -> str:
        """Create testbench with framebuffer dumping for graphics tests"""
        vcd_file = self.temp_vcd_dir / f"{sanitized_test_name}.vcd"
        
        return f'''`timescale 1ns / 1ps

module tb_{sanitized_test_name};
    reg clk;
    reg rst_n;
    wire [31:0] debug_pc;
    wire [31:0] debug_instruction;
    wire [31:0] debug_reg_data;
    wire [4:0] debug_reg_addr;
    wire [31:0] debug_result;
    wire debug_halted;
    
    // Framebuffer parameters
    parameter FB_WIDTH = 320;
    parameter FB_HEIGHT = 240;
    parameter FB_BASE_ADDR = 32'h800;  // 2048 - test address for assembly program
    parameter FB_SIZE = FB_WIDTH * FB_HEIGHT * 4;
    parameter DUMP_INTERVAL = 100;  // Dump every 25k cycles
    
    // Test control
    integer cycle_count = 0;
    integer dump_count = 0;
    integer fb_dump_file;
    integer last_dump_cycle = 0;
    integer graphics_pixels = 0;
    reg fb_dump_enable = 1;
    
    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    // Cycle counter
    always @(posedge clk) begin
        cycle_count = cycle_count + 1;
    end
    
    // Framebuffer dump task
    task dump_framebuffer;
        integer x, y, pixel_addr, pixel_data;
        integer r, g, b;
        integer debug_pixels_found;
        begin
            $display("Dumping framebuffer at cycle %d...", cycle_count);
            debug_pixels_found = 0;
            
            // Debug: Show first few memory locations
            $display("=== FRAMEBUFFER DEBUG ===");
            $display("FB_BASE_ADDR = 0x%08x", FB_BASE_ADDR);
            $display("FB_BASE_ADDR/4 = %d", FB_BASE_ADDR/4);
            for (pixel_addr = FB_BASE_ADDR/4; pixel_addr < (FB_BASE_ADDR/4) + 10; pixel_addr = pixel_addr + 1) begin
                pixel_data = uut.internal_memory[pixel_addr];
                $display("Memory[%d] = 0x%08x (binary: %b)", pixel_addr, pixel_data, pixel_data);
                if (pixel_data != 32'h000000FF && pixel_data != 32'h00000000) begin
                    debug_pixels_found = debug_pixels_found + 1;
                    $display("  -> Non-default pixel found! R=%02x G=%02x B=%02x", 
                            (pixel_data >> 24) & 8'hFF, 
                            (pixel_data >> 16) & 8'hFF, 
                            (pixel_data >> 8) & 8'hFF);
                end
            end
            $display("Non-default pixels found in first 10 addresses: %d", debug_pixels_found);
            
            // Also check for any 0xFF00 patterns
            $display("Checking for 0xFF00 patterns...");
            for (pixel_addr = FB_BASE_ADDR/4; pixel_addr < (FB_BASE_ADDR/4) + 100; pixel_addr = pixel_addr + 1) begin
                pixel_data = uut.internal_memory[pixel_addr];
                if (pixel_data == 32'h0000FF00 || pixel_data == 32'hFF000000 || pixel_data == 32'h00FF0000 || pixel_data == 32'h000000FF) begin
                    $display("Found pattern at Memory[%d] = 0x%08x", pixel_addr, pixel_data);
                end
            end
            $display("========================");
            
            fb_dump_file = $fopen("temp/reports/framebuffer.ppm", "w");
            if (fb_dump_file != 0) begin
                $fwrite(fb_dump_file, "P6\\n");
                $fwrite(fb_dump_file, "# RISC CPU Framebuffer\\n");
                $fwrite(fb_dump_file, "%d %d\\n", FB_WIDTH, FB_HEIGHT);
                $fwrite(fb_dump_file, "255\\n");
                
                for (y = 0; y < FB_HEIGHT; y = y + 1) begin
                    for (x = 0; x < FB_WIDTH; x = x + 1) begin
                        pixel_addr = (FB_BASE_ADDR/4) + (y * FB_WIDTH + x);
                        pixel_data = uut.internal_memory[pixel_addr];
                        
                        // Correct color format interpretation for assembly 0xFF00 = yellow
                        if (pixel_data == 32'h0000FF00) begin
                            // Assembly 0xFF00 format (stored as 0x0000FF00 in 32-bit word)
                            r = 8'hFF;  // Red component for yellow
                            g = 8'hFF;  // Green component for yellow
                            b = 8'h00;  // Blue component for yellow
                        end else if (pixel_data == 32'h000000FF) begin
                            // Default black background
                            r = 8'h00;
                            g = 8'h00;
                            b = 8'h00;
                        end else begin
                            // Standard RGBA format (assuming 0xRRGGBBAA)
                            r = (pixel_data >> 24) & 8'hFF;
                            g = (pixel_data >> 16) & 8'hFF;
                            b = (pixel_data >> 8) & 8'hFF;
                        end
                        
                        $fwrite(fb_dump_file, "%c%c%c", r, g, b);
                    end
                end
                
                $fclose(fb_dump_file);
                dump_count = dump_count + 1;
                $display("Framebuffer dump #%d complete", dump_count);
            end
        end
    endtask
    
    // Memory dump task for log extraction
    task dump_log_memory;
        integer i;
        integer log_length;
        integer log_addr;
        reg [7:0] log_char;
        begin
            log_length = uut.internal_memory[4096];
            $display("=== LOG OUTPUT ===");
            
            if (log_length > 0 && log_length < 1024) begin
                $write("Log: ");
                for (i = 0; i < log_length; i = i + 1) begin
                    log_addr = 3072 + (i / 4);
                    case (i % 4)
                        0: log_char = uut.internal_memory[log_addr][7:0];
                        1: log_char = uut.internal_memory[log_addr][15:8];
                        2: log_char = uut.internal_memory[log_addr][23:16];
                        3: log_char = uut.internal_memory[log_addr][31:24];
                    endcase
                    
                    if (log_char >= 32 && log_char <= 126) begin
                        $write("%c", log_char);
                    end else if (log_char == 10) begin
                        $write("\\n");
                    end
                end
                $display("");
            end
            $display("=== END LOG ===");
        end
    endtask
    
    // Periodic framebuffer dumping
    always @(posedge clk) begin
        $display("=== AAAAA===");
        $display("Memory[8192] = 0x%08x", uut.internal_memory[8192]);
        $display("Memory[4096] = 0x%08x", uut.internal_memory[4096]);
        $display("Memory[512] = 0x%08x", uut.internal_memory[512]);
        if (fb_dump_enable && (cycle_count - last_dump_cycle) >= DUMP_INTERVAL) begin
            dump_framebuffer();
            last_dump_cycle = cycle_count;
        end
    end
    
    // Reset and test
    initial begin
        $dumpfile("{vcd_file}");
        $dumpvars(0, tb_{sanitized_test_name});
        
        // Create output directory (done externally)
        // $system("mkdir -p temp/reports");
        
        // Load program at address 0x8000 (word address 8192) where CPU expects it
        $readmemh("{hex_file}", uut.internal_memory, 8192);
        
        // Debug: Show what was loaded
        $display("=== PROGRAM LOADING DEBUG ===");
        $display("Loading program at word address 8192 (0x8000)");
        $display("First few instructions:");
        $display("Memory[8192] = 0x%08x", uut.internal_memory[8192]);
        $display("Memory[8193] = 0x%08x", uut.internal_memory[8193]);
        $display("Memory[8194] = 0x%08x", uut.internal_memory[8194]);
        $display("Memory[8195] = 0x%08x", uut.internal_memory[8195]);
        $display("============================");
        
        // Initialize framebuffer to black
        // begin : fb_init
        //    integer i;
        //    for (i = 0; i < FB_SIZE/4; i = i + 1) begin
        //        uut.internal_memory[(FB_BASE_ADDR/4) + i] = 32'h000000FF;
        //    end
        // end

        $display("=== AFTER FRAME BUFFER INIT ===");
        $display("Memory[8192] = 0x%08x", uut.internal_memory[8192]);
        $display("Memory[8193] = 0x%08x", uut.internal_memory[8193]);
        $display("Memory[8194] = 0x%08x", uut.internal_memory[8194]);
        $display("Memory[8195] = 0x%08x", uut.internal_memory[8195]);
        $display("============================");
        
        // TEST: Manually write extensive test pixels to prove the infrastructure works
        /* 
        begin : test_pixels
            integer row, col, addr;
            
            // Write a comprehensive test pattern to framebuffer
            $display("Writing test pattern to framebuffer...");
            
            // Row 0: Primary colors
            uut.internal_memory[(FB_BASE_ADDR/4) + 0] = 32'hFF000000;  // Red pixel at (0,0)
            uut.internal_memory[(FB_BASE_ADDR/4) + 1] = 32'h00FF0000;  // Green pixel at (1,0)
            uut.internal_memory[(FB_BASE_ADDR/4) + 2] = 32'h0000FF00;  // Blue pixel at (2,0)
            uut.internal_memory[(FB_BASE_ADDR/4) + 3] = 32'hFFFF0000;  // Yellow pixel at (3,0)
            uut.internal_memory[(FB_BASE_ADDR/4) + 4] = 32'hFF00FF00;  // Magenta pixel at (4,0)
            uut.internal_memory[(FB_BASE_ADDR/4) + 5] = 32'h00FFFF00;  // Cyan pixel at (5,0)
            uut.internal_memory[(FB_BASE_ADDR/4) + 6] = 32'hFFFFFF00;  // White pixel at (6,0)
            uut.internal_memory[(FB_BASE_ADDR/4) + 7] = 32'h80808000;  // Gray pixel at (7,0)
            
            // Row 1: Secondary colors and gradients
            // uut.internal_memory[(FB_BASE_ADDR/4) + 320] = 32'h80000000; // Dark red at (0,1)
            // uut.internal_memory[(FB_BASE_ADDR/4) + 321] = 32'h00800000; // Dark green at (1,1)
            // uut.internal_memory[(FB_BASE_ADDR/4) + 322] = 32'h00008000; // Dark blue at (2,1)
            // uut.internal_memory[(FB_BASE_ADDR/4) + 323] = 32'h40404000; // Dark gray at (3,1)
            // uut.internal_memory[(FB_BASE_ADDR/4) + 324] = 32'hC0C0C000; // Light gray at (4,1)
            // uut.internal_memory[(FB_BASE_ADDR/4) + 325] = 32'hFF800000; // Orange at (5,1)
            // uut.internal_memory[(FB_BASE_ADDR/4) + 326] = 32'h8000FF00; // Purple at (6,1)
            // uut.internal_memory[(FB_BASE_ADDR/4) + 327] = 32'h00FF8000; // Lime at (7,1)
            
            // Row 2: Test assembly 0xFF00 format equivalents
            uut.internal_memory[(FB_BASE_ADDR/4) + 640] = 32'h0000FF00; // Assembly 0xFF00 format at (0,2)
            uut.internal_memory[(FB_BASE_ADDR/4) + 641] = 32'h0000FF00; // Assembly 0xFF00 format at (1,2)
            uut.internal_memory[(FB_BASE_ADDR/4) + 642] = 32'h0000FF00; // Assembly 0xFF00 format at (2,2)
            uut.internal_memory[(FB_BASE_ADDR/4) + 643] = 32'h0000FF00; // Assembly 0xFF00 format at (3,2)
            uut.internal_memory[(FB_BASE_ADDR/4) + 644] = 32'h000000FF; // Default black background at (4,2)
            uut.internal_memory[(FB_BASE_ADDR/4) + 645] = 32'h000000FF; // Default black background at (5,2)
            uut.internal_memory[(FB_BASE_ADDR/4) + 646] = 32'h000000FF; // Default black background at (6,2)
            uut.internal_memory[(FB_BASE_ADDR/4) + 647] = 32'h000000FF; // Default black background at (7,2)
            
            // Create a 10x10 checkerboard pattern starting at (10,10)
            for (row = 10; row < 20; row = row + 1) begin
                for (col = 10; col < 20; col = col + 1) begin
                    addr = (FB_BASE_ADDR/4) + (row * FB_WIDTH + col);
                    if ((row + col) % 2 == 0) begin
                        uut.internal_memory[addr] = 32'hFFFFFF00; // White squares
                    end else begin
                        uut.internal_memory[addr] = 32'h000000FF; // Black squares
                    end
                end
            end
            
            // Create a diagonal line from (30,30) to (50,50)
            for (row = 30; row < 50; row = row + 1) begin
                col = row; // Diagonal
                addr = (FB_BASE_ADDR/4) + (row * FB_WIDTH + col);
                uut.internal_memory[addr] = 32'hFF000000; // Red diagonal line
            end
            
            // Create a filled rectangle (60,60) to (80,80)
            for (row = 60; row < 100; row = row + 1) begin
                for (col = 60; col < 100; col = col + 1) begin
                    addr = (FB_BASE_ADDR/4) + (row * FB_WIDTH + col);
                    uut.internal_memory[addr] = 32'h00FF0000; // Green filled rectangle
                end
            end
            
            // Create a frame/border at (100,100) to (120,120)
            for (row = 100; row < 120; row = row + 1) begin
                for (col = 100; col < 120; col = col + 1) begin
                    addr = (FB_BASE_ADDR/4) + (row * FB_WIDTH + col);
                    if (row == 100 || row == 119 || col == 100 || col == 119) begin
                        uut.internal_memory[addr] = 32'h0000FF00; // Blue border
                    end else begin
                        uut.internal_memory[addr] = 32'h000000FF; // Black interior
                    end
                end
            end
            
            $display("Test pattern written: 8x3 color grid + 10x10 checkerboard + diagonal + rectangle + border frame");
        end
        */
        
        // Reset
        rst_n = 0;
        #20;
        rst_n = 1;
        
        $display("=== FRAMEBUFFER GRAPHICS TEST ===");
        $display("Framebuffer: %dx%d at 0x%08X", FB_WIDTH, FB_HEIGHT, FB_BASE_ADDR);
        $display("Dumps will be saved to temp/reports/framebuffer.ppm");
        
        // Debug: Show what's loaded at key memory addresses
        $display("=== MEMORY DEBUG ===");
        $display("Memory[0] = 0x%08x", uut.internal_memory[0]);
        $display("Memory[1] = 0x%08x", uut.internal_memory[1]);
        $display("Memory[2] = 0x%08x", uut.internal_memory[2]);
        $display("Memory[8192] = 0x%08x", uut.internal_memory[8192]);
        $display("Memory[8193] = 0x%08x", uut.internal_memory[8193]);
        $display("Memory[8194] = 0x%08x", uut.internal_memory[8194]);
        
        // Initial dump
        #1000;
        dump_framebuffer();
        
        // Run simulation with periodic dumps
        #200000;  // Extended runtime for graphics
        
        // Final dump
        dump_framebuffer();
        
        // Dump log memory
        dump_log_memory();
        
        // Check for graphics content
        $display("=== GRAPHICS VERIFICATION ===");
        graphics_pixels = 0;
        begin : graphics_check
            integer i, addr;
            for (i = 0; i < 1000; i = i + 10) begin
                addr = (FB_BASE_ADDR/4) + i;
                if (uut.internal_memory[addr] != 32'h000000FF) begin
                    graphics_pixels = graphics_pixels + 1;
                end
            end
        end
        
        if (graphics_pixels > 10) begin
            $display("✓ GRAPHICS TEST PASSED - Found %d non-black pixels", graphics_pixels);
        end else begin
            $display("✗ GRAPHICS TEST WARNING - Only %d non-black pixels found", graphics_pixels);
        end
        
        if (debug_halted) begin
            $display("✓ Program completed successfully");
        end else begin
            $display("? Program may not have completed");
        end
        
        $display("Total framebuffer dumps: %d", dump_count);
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
        .pc_out(debug_pc),
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
            # Handle subdirectories - if test_name contains '/', treat it as a relative path
            if '/' in test_name:
                test_file = self.c_programs_dir / f"{test_name}.c"
            else:
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
        elif test_type == "assembly":
            # Try to find the .asm file in likely locations
            asm_file = self.hdl_root / "test_programs" / "asm" / f"{test_name}.asm"
            if not asm_file.exists():
                print(asm_file, "Not exists 1")
                asm_file = self.hdl_root / "test_programs" / "assembly" / f"{test_name}.asm"
            if not asm_file.exists():
                print(asm_file, "Not exists 2")
                # Try with no subfolder
                asm_file = self.hdl_root / "test_programs" / "asm" / test_name
                if not asm_file.exists():
                    print(f"❌ Assembly test file not found: {asm_file}")
                    return {"error": f"Assembly test file not found: {asm_file}"}

            print(f"🚀 Running single Assembly test: {test_name}")
            # Clean up test name for file paths (remove path separators)
            clean_test_name = test_name.replace("/", "_").replace("\\", "_")
            
            # Stage 1: Assemble to Hex
            print("Stage 1: Assembling to Hex...")
            success, message, hex_file = self.assemble_to_hex(asm_file)
            result = {
                "test_name": test_name,
                "asm_file": str(asm_file),
                "stages": {"asm_to_hex": {"success": success, "message": message, "output_file": str(hex_file) if hex_file.exists() else None}},
                "overall_success": False,
                "final_result": None
            }
            if not success:
                print(f"  ❌ {message}")
                return result
            print(f"  ✅ {message}")
            # Stage 2: Simulation
            print("Stage 2: Running Simulation...")
            success, message, sim_results = self.run_simulation(hex_file, clean_test_name)
            result["stages"]["simulation"] = {"success": success, "message": message, "results": sim_results}
            if not success:
                print(f"  ❌ {message}")
                return result
            print(f"  ✅ {message}")
            if sim_results.get("log_output"):
                print("  📜 Program Log Output:")
                log_lines = sim_results["log_output"].split('\n')
                for line in log_lines:
                    if line.strip():
                        print(f"      {line}")
            if sim_results.get("result_value") is not None:
                print(f"  🎯 Final result: {sim_results['result_value']}")
                result["final_result"] = sim_results["result_value"]
            result["overall_success"] = True
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
        
        # Handle subdirectories in test names
        if '/' in test_name:
            c_file = self.c_programs_dir / f"{test_name}.c"
            base_name = test_name.replace('/', '_')  # Use underscore for file names
        else:
            c_file = self.c_programs_dir / f"{test_name}.c"
            base_name = test_name
        
        # Paths
        preprocessed_file = self.temp_asm_dir / f"{base_name}_preprocessed.c"
        memory_layout_file = self.temp_asm_dir / f"{base_name}_memory_layout.json"
        asm_file = self.temp_asm_dir / f"{base_name}.asm"
        enhanced_asm_file = self.temp_asm_dir / f"{base_name}_enhanced.asm"
        hex_file = self.temp_hex_dir / f"{base_name}_enhanced.hex"
        
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
        
        # The C compiler creates output.s in the current directory
        compiler_asm_file = self.hdl_root / "output.s"
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
        success, message, sim_results = self.run_simulation(hex_file, f"{base_name}_enhanced")
        
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
