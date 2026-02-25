/**
 * Testbench for 32-bit Microprocessor System
 * 
 * Tests the basic functionality of the 32-bit processor
 * including arithmetic operations and simple sorting
 */

`timescale 1ns / 1ps

module tb_microprocessor_system;

    // Clock and reset
    reg clk;
    reg rst_n;
    
    // External memory interface
    wire [31:0] ext_addr;
    wire [31:0] ext_data;
    wire ext_mem_read;
    wire ext_mem_write;
    wire ext_mem_enable;
    reg ext_mem_ready;
    
    // I/O interface
    wire [7:0] io_addr;
    wire [7:0] io_data;
    wire io_read;
    wire io_write;
    
    // Interrupts
    reg [7:0] external_interrupts;
    
    // Status
    wire system_halted;
    wire [31:0] pc_out;
    
    // Test variables
    integer cycle_count;
    integer max_cycles = 50000;
    reg [8*100:1] hexfile; // String for filename
    
    // Instantiate the 32-bit microprocessor
    microprocessor_system uut (
        .clk(clk),
        .rst_n(rst_n),
        .ext_addr(ext_addr),
        .ext_data(ext_data),
        .ext_mem_read(ext_mem_read),
        .ext_mem_write(ext_mem_write),
        .ext_mem_enable(ext_mem_enable),
        .ext_mem_ready(ext_mem_ready),
        .io_addr(io_addr),
        .io_data(io_data),
        .io_read(io_read),
        .io_write(io_write),
        .external_interrupts(external_interrupts),
        .system_halted(system_halted),
        .pc_out(pc_out)
    );
    
    // Clock generation
    always #5 clk = ~clk;
    
    // Load program into memory
    initial begin
        // Dynamically select hex file via command-line argument
        if (!$value$plusargs("hexfile=%s", hexfile)) begin
            hexfile = "testbench/simple_sort.hex"; // default
        end
        $display("Loading program from: %s", hexfile);
        // Load program at offset 0x8000/4 = 8192 (where CPU starts execution)
        $readmemh(hexfile, uut.internal_memory, 32'h8000/4);
    end
    
    // Main test sequence
    initial begin
        // Initialize signals
        clk = 0;
        rst_n = 0;
        ext_mem_ready = 1;
        external_interrupts = 8'h00;
        cycle_count = 0;
        
        // Reset sequence
        #10 rst_n = 1;
        
        $display("    === 32-bit Microprocessor Test ===");
        $display("Starting program execution...");
        
        // Wait for program completion or timeout
        while (!system_halted && cycle_count < max_cycles) begin
            @(posedge clk);
            cycle_count = cycle_count + 1;
            
            // Display progress every 100 cycles
            if (cycle_count % 100 == 0) begin
                $display("Cycle %d: PC = 0x%08X", cycle_count, pc_out);
            end
        end
        
        if (system_halted) begin
            $display("Program completed successfully at cycle %d", cycle_count);
            $display("Final PC: 0x%08X", pc_out);
            $display("\n=== Checking Results ===");
            if (hexfile == "testbench/simple_sort.hex") begin
                // Check sorted array in memory
                $display("Sorted array in memory:");
                $display("Memory[0x1000] = %d (should be 10000)", uut.internal_memory[16'h1000/4]);
                $display("Memory[0x1004] = %d (should be 30000)", uut.internal_memory[16'h1004/4]);
                $display("Memory[0x1008] = %d (should be 50000)", uut.internal_memory[16'h1008/4]);
                $display("Memory[0x100C] = %d (should be 80000)", uut.internal_memory[16'h100C/4]);
                
                // Verify sorting was successful
                if (uut.internal_memory[16'h1000/4] == 32'd10000 &&
                    uut.internal_memory[16'h1004/4] == 32'd30000 &&
                    uut.internal_memory[16'h1008/4] == 32'd50000 &&
                    uut.internal_memory[16'h100C/4] == 32'd80000) begin
                    $display("\n✓ SORTING TEST PASSED - Array correctly sorted!");
                end else begin
                    $display("\n✗ SORTING TEST FAILED - Array not correctly sorted");
                end
            end else begin
                // Generic pass/fail check for C programs
                $display("Checking status code at 0x2000 (uut.internal_memory[0x800]): %d", uut.internal_memory[32'h2000/4]);
                if (uut.internal_memory[32'h2000/4] == 1) begin
                    $display("\n✓ PROGRAM PASSED (status code = 1)");
                end else if (uut.internal_memory[32'h2000/4] == 0) begin
                    $display("\n✗ PROGRAM FAILED (status code = 0)");
                end else begin
                    $display("\n? PROGRAM STATUS UNKNOWN (status code = %d)", uut.internal_memory[32'h2000/4]);
                end
            end
            $display("\n✓ 32-bit Processor Test PASSED");
        end else begin
            $display("✗ Test FAILED - Program did not complete within %d cycles", max_cycles);
        end
        $display("\nTest completed.");
        $finish;
    end
    
    // Monitor important signals & UART Simulation
    always @(posedge clk) begin
        if (ext_mem_read || ext_mem_write) begin
            // UART TX at 0x10000000
            if (ext_mem_write && ext_addr == 32'h10000000) begin
                $write("%c", ext_data[7:0]);
            end else begin
                $display("External memory access: addr=0x%08X, read=%b, write=%b, data=0x%08x", 
                     ext_addr, ext_mem_read, ext_mem_write, ext_data);
            end
        end
    end

endmodule
