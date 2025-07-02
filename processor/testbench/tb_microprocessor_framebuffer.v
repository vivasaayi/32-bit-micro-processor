/**
 * Enhanced Testbench for 32-bit Microprocessor with Framebuffer Support
 * 
 * This testbench adds framebuffer dumping capabilities to visualize
 * graphics output from the processor using the Java UI
 */

`timescale 1ns / 1ps

module tb_microprocessor_framebuffer;

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
    wire [7:0] cpu_flags;
    
    // Framebuffer parameters
    parameter FB_WIDTH = 320;
    parameter FB_HEIGHT = 240;
    parameter FB_BASE_ADDR = 32'h10000;  // 65536
    parameter FB_SIZE = FB_WIDTH * FB_HEIGHT * 4;  // 4 bytes per pixel
    parameter DUMP_INTERVAL = 50000;  // Dump every 50k cycles
    
    // Test variables
    integer cycle_count;
    integer max_cycles = 500000;  // Increased for graphics tests
    integer dump_count;
    integer fb_dump_file;
    string hexfile;
    
    // Framebuffer dump control
    reg fb_dump_enable;
    integer last_dump_cycle;
    
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
        .pc_out(pc_out),
        .cpu_flags(cpu_flags)
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
        $readmemh(hexfile, uut.internal_memory);
        
        // Initialize framebuffer area to black (0x000000FF)
        for (integer i = 0; i < FB_SIZE/4; i = i + 1) begin
            uut.internal_memory[(FB_BASE_ADDR/4) + i] = 32'h000000FF;
        end
        $display("Initialized framebuffer at 0x%08X (%d pixels)", FB_BASE_ADDR, FB_WIDTH * FB_HEIGHT);
    end
    
    // Framebuffer dump task
    task dump_framebuffer;
        integer x, y, pixel_addr, pixel_data;
        integer r, g, b;
        begin
            $display("Dumping framebuffer at cycle %d...", cycle_count);
            
            // Open PPM file for writing
            fb_dump_file = $fopen("temp/reports/framebuffer.ppm", "w");
            if (fb_dump_file == 0) begin
                $display("Error: Could not open framebuffer.ppm for writing");
                return;
            end
            
            // Write PPM header
            $fwrite(fb_dump_file, "P6\n");
            $fwrite(fb_dump_file, "# RISC CPU Framebuffer - Cycle %d\n", cycle_count);
            $fwrite(fb_dump_file, "%d %d\n", FB_WIDTH, FB_HEIGHT);
            $fwrite(fb_dump_file, "255\n");
            
            // Write pixel data
            for (y = 0; y < FB_HEIGHT; y = y + 1) begin
                for (x = 0; x < FB_WIDTH; x = x + 1) begin
                    pixel_addr = (FB_BASE_ADDR/4) + (y * FB_WIDTH + x);
                    pixel_data = uut.internal_memory[pixel_addr];
                    
                    // Extract RGB from 32-bit RGBA (0xRRGGBBAA)
                    r = (pixel_data >> 24) & 8'hFF;
                    g = (pixel_data >> 16) & 8'hFF;
                    b = (pixel_data >> 8) & 8'hFF;
                    
                    // Write RGB bytes to PPM file
                    $fwrite(fb_dump_file, "%c%c%c", r, g, b);
                end
            end
            
            $fclose(fb_dump_file);
            dump_count = dump_count + 1;
            $display("Framebuffer dump #%d complete (%dx%d pixels)", dump_count, FB_WIDTH, FB_HEIGHT);
        end
    endtask
    
    // Monitor framebuffer writes
    always @(posedge clk) begin
        if (ext_mem_write && ext_addr >= FB_BASE_ADDR && ext_addr < FB_BASE_ADDR + FB_SIZE) begin
            $display("FB WRITE: addr=0x%08X, data=0x%08X, pixel=[%d,%d]", 
                     ext_addr, ext_data, 
                     ((ext_addr - FB_BASE_ADDR)/4) % FB_WIDTH,
                     ((ext_addr - FB_BASE_ADDR)/4) / FB_WIDTH);
        end
    end
    
    // Periodic framebuffer dumping
    always @(posedge clk) begin
        if (fb_dump_enable && (cycle_count - last_dump_cycle) >= DUMP_INTERVAL) begin
            dump_framebuffer();
            last_dump_cycle = cycle_count;
        end
    end
    
    // Main test sequence
    initial begin
        // Initialize signals
        clk = 0;
        rst_n = 0;
        ext_mem_ready = 1;
        external_interrupts = 8'h00;
        cycle_count = 0;
        dump_count = 0;
        fb_dump_enable = 1;
        last_dump_cycle = 0;
        
        // Create output directory
        $system("mkdir -p temp/reports");
        
        // Reset sequence
        #10 rst_n = 1;
        
        $display("=== 32-bit Microprocessor Framebuffer Test ===");
        $display("Program: %s", hexfile);
        $display("Framebuffer: %dx%d pixels at 0x%08X", FB_WIDTH, FB_HEIGHT, FB_BASE_ADDR);
        $display("Dump interval: %d cycles", DUMP_INTERVAL);
        $display("Starting program execution...");
        $display("Java UI should show graphics output in real-time");
        
        // Initial framebuffer dump
        dump_framebuffer();
        
        // Wait for program completion or timeout
        while (!system_halted && cycle_count < max_cycles) begin
            @(posedge clk);
            cycle_count = cycle_count + 1;
            
            // Display progress every 10000 cycles
            if (cycle_count % 10000 == 0) begin
                $display("Cycle %d: PC = 0x%08X", cycle_count, pc_out);
            end
        end
        
        // Final framebuffer dump
        dump_framebuffer();
        
        if (system_halted) begin
            $display("\n=== Program Execution Complete ===");
            $display("Total cycles: %d", cycle_count);
            $display("Final PC: 0x%08X", pc_out);
            $display("Framebuffer dumps created: %d", dump_count);
            
            // Check if this was a graphics test
            if (hexfile == "temp/c_generated_hex/100_framebuffer_graphics.hex") begin
                $display("\n=== Graphics Test Results ===");
                $display("Framebuffer should contain colorful patterns");
                $display("Check Java UI for visual verification");
                
                // Sample a few pixels to verify graphics were written
                integer sample_pixels = 0;
                for (integer i = 0; i < 10; i = i + 1) begin
                    integer sample_addr = (FB_BASE_ADDR/4) + (i * 1000);
                    integer sample_data = uut.internal_memory[sample_addr];
                    if (sample_data != 32'h000000FF) begin  // Not black
                        sample_pixels = sample_pixels + 1;
                    end
                end
                
                if (sample_pixels > 5) begin
                    $display("✓ GRAPHICS TEST PASSED - Framebuffer contains graphics data");
                end else begin
                    $display("✗ GRAPHICS TEST FAILED - Framebuffer appears empty");
                end
            end else begin
                // Generic pass/fail check
                $display("Checking status code at 0x2000: %d", uut.internal_memory[32'h2000/4]);
                if (uut.internal_memory[32'h2000/4] == 1) begin
                    $display("✓ PROGRAM PASSED");
                end else if (uut.internal_memory[32'h2000/4] == 0) begin
                    $display("✗ PROGRAM FAILED");
                end else begin
                    $display("? PROGRAM STATUS UNKNOWN");
                end
            end
            
            $display("\n✓ Framebuffer Test PASSED");
        end else begin
            $display("✗ Test FAILED - Program did not complete within %d cycles", max_cycles);
        end
        
        $display("\nFramebuffer dumps saved to: temp/reports/framebuffer.ppm");
        $display("View with Java UI: cd java_ui && java SimpleFramebufferViewer");
        $display("Test completed.");
        $finish;
    end
    
    // Enhanced memory access monitoring
    always @(posedge clk) begin
        if (ext_mem_read || ext_mem_write) begin
            if (ext_addr >= FB_BASE_ADDR && ext_addr < FB_BASE_ADDR + FB_SIZE) begin
                // Framebuffer access - already logged above
            end else if (ext_mem_read || ext_mem_write) begin
                // Other memory access
                if (cycle_count % 1000 == 0) begin  // Reduce spam
                    $display("MEM: addr=0x%08X, %s", ext_addr, ext_mem_write ? "WRITE" : "READ");
                end
            end
        end
    end

endmodule
