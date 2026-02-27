#!/usr/bin/env python3
"""
Simple test runner for the bouncing rectangle assembly program
"""

import subprocess
import sys
import os
from pathlib import Path

def run_bouncing_rectangle_test():
    hdl_root = Path("/Users/rajanpanneerselvam/work/hdl")
    temp_dir = hdl_root / "temp"
    
    # File paths
    asm_file = hdl_root / "test_programs/assembly/108_bouncing_rectangle_fixed.asm"
    hex_file = temp_dir / "108_bouncing_rectangle_fixed.hex"
    testbench_file = temp_dir / "108_bouncing_rectangle_fixed_testbench.v"
    vvp_file = temp_dir / "108_bouncing_rectangle_fixed_testbench.vvp"
    vcd_file = temp_dir / "108_bouncing_rectangle_fixed.vcd"
    log_file = temp_dir / "108_bouncing_rectangle_fixed.log"
    
    print("🎮 Testing Bouncing Rectangle Animation")
    print("=====================================")
    
    # Step 1: Assemble
    print("Step 1: Assembling...")
    assembler = temp_dir / "assembler"
    cmd = [str(assembler), str(asm_file), str(hex_file)]
    
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"❌ Assembly failed: {result.stderr}")
        return False
    
    print(f"✅ Assembly successful: {hex_file}")
    
    # Step 2: Create framebuffer testbench
    print("Step 2: Creating framebuffer testbench...")
    
    testbench_content = f'''`timescale 1ns / 1ps

module tb_bouncing_rectangle_fixed;
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
    parameter FB_BASE_ADDR = 32'h800;  // 2048 - matches assembly program
    parameter FB_SIZE = FB_WIDTH * FB_HEIGHT;
    parameter DUMP_INTERVAL = 1000;  // Dump every 1000 cycles for animation
    
    // Test control
    integer cycle_count;
    integer dump_count;
    integer fb_dump_file;
    
    initial begin
        cycle_count = 0;
        dump_count = 0;
    end
    
    // Clock generation (100MHz)
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10ns period = 100MHz
    end
    
    // Cycle counter and periodic dump
    always @(posedge clk) begin
        cycle_count = cycle_count + 1;
        
        // Periodic framebuffer dump for animation
        if (cycle_count % DUMP_INTERVAL == 0 && cycle_count > 0) begin
            dump_framebuffer();
        end
    end
    
    // Framebuffer dump task
    task dump_framebuffer;
        integer x, y, pixel_addr, pixel_data;
        integer r, g, b, a;
        integer non_bg_pixels;
        begin
            $display("=== FRAMEBUFFER DUMP %d at cycle %d ===", dump_count, cycle_count);
            
            // Open file for writing
            fb_dump_file = $fopen("/Users/rajanpanneerselvam/work/hdl/temp/reports/framebuffer.ppm", "wb");
            if (fb_dump_file == 0) begin
                $display("ERROR: Could not open framebuffer file for writing");
            end else begin
                $display("Framebuffer dump file opened successfully");
                
                // Write PPM header
                $fwrite(fb_dump_file, "P6\\n%0d %0d\\n255\\n", FB_WIDTH, FB_HEIGHT);
                
                non_bg_pixels = 0;
                
                // Write pixel data
                for (y = 0; y < FB_HEIGHT; y = y + 1) begin
                    for (x = 0; x < FB_WIDTH; x = x + 1) begin
                        pixel_addr = (FB_BASE_ADDR/4) + (y * FB_WIDTH) + x;
                        pixel_data = uut.internal_memory[pixel_addr];
                        
                        // Extract RGBA (stored as 0xRRGGBBAA)
                        r = (pixel_data >> 24) & 8'hFF;
                        g = (pixel_data >> 16) & 8'hFF;
                        b = (pixel_data >> 8) & 8'hFF;
                        a = pixel_data & 8'hFF;
                        
                        // Count non-background pixels for debug
                        if (pixel_data != 32'h000000FF) begin
                            non_bg_pixels = non_bg_pixels + 1;
                        end
                        
                        // Write RGB (PPM P6 format)
                        $fwrite(fb_dump_file, "%c%c%c", r, g, b);
                    end
                end
                
                $fclose(fb_dump_file);
                
                $display("Framebuffer dumped successfully!");
                $display("Non-background pixels: %d", non_bg_pixels);
                $display("=== END FRAMEBUFFER DUMP %d ===", dump_count);
                
                dump_count = dump_count + 1;
            end
        end
    endtask
    
    // Reset and test
    initial begin
        $dumpfile("{vcd_file}");
        $dumpvars(0, tb_bouncing_rectangle_fixed);
        
        // Load program at correct memory offset (0x8000 = word address 8192)
        $readmemh("{hex_file}", uut.internal_memory, 8192);
        
        $display("Program loaded from {hex_file}");
        $display("Starting animation simulation...");
        
        // Reset
        rst_n = 0;
        #100;
        rst_n = 1;
        
        $display("Reset released, program starting...");
        
        // Run simulation for animation (limited time for testing)
        #10000000;  // 10 million cycles - enough for several animation frames
        
        $display("Simulation completed");
        
        if (debug_halted) begin
            $display("✓ Program completed successfully");
        end else begin
            $display("⚠ Program did not halt (this is expected for infinite animation loop)");
        end
        
        // Final framebuffer dump
        dump_framebuffer();
        
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
        .debug_pc(debug_pc),
        .debug_instruction(debug_instruction),
        .debug_reg_data(debug_reg_data),
        .debug_reg_addr(debug_reg_addr),
        .debug_result(debug_result),
        .debug_halted(debug_halted)
    );
    
endmodule
'''
    
    with open(testbench_file, 'w') as f:
        f.write(testbench_content)
    
    print(f"✅ Testbench created: {testbench_file}")
    
    # Step 3: Compile testbench
    print("Step 3: Compiling testbench...")
    
    compile_cmd = [
        "iverilog",
        "-o", str(vvp_file),
        str(testbench_file),
        str(hdl_root / "AruviCore" / "microprocessor_system.v"),
        str(hdl_root / "AruviCore" / "cpu" / "cpu_core.v"),
        str(hdl_root / "AruviCore" / "cpu" / "alu.v"),
        str(hdl_root / "AruviCore" / "cpu" / "register_file.v"),
        str(hdl_root / "AruviCore" / "memory" / "memory_controller.v"),
        str(hdl_root / "AruviCore" / "memory" / "mmu.v"),
        str(hdl_root / "AruviCore" / "io" / "uart.v"),
        str(hdl_root / "AruviCore" / "io" / "timer.v"),
        str(hdl_root / "AruviCore" / "io" / "interrupt_controller.v")
    ]
    
    result = subprocess.run(compile_cmd, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"❌ Compilation failed: {result.stderr}")
        return False
    
    print(f"✅ Compilation successful: {vvp_file}")
    
    # Step 4: Run simulation
    print("Step 4: Running simulation...")
    print("🎬 This will generate animated framebuffer dumps...")
    
    run_cmd = ["vvp", str(vvp_file)]
    
    result = subprocess.run(run_cmd, capture_output=True, text=True, timeout=60)
    
    # Save output
    with open(log_file, 'w') as f:
        f.write("=== STDOUT ===\\n")
        f.write(result.stdout)
        f.write("\\n=== STDERR ===\\n")
        f.write(result.stderr)
    
    print(f"📄 Simulation log saved: {log_file}")
    
    if result.returncode == 0:
        print("✅ Simulation completed successfully!")
        print("🎮 Check the framebuffer.ppm file for animation frames")
        print("💡 You can now use the Live Monitor in your IDE!")
        return True
    else:
        print(f"❌ Simulation failed: {result.stderr}")
        return False

if __name__ == "__main__":
    success = run_bouncing_rectangle_test()
    sys.exit(0 if success else 1)
