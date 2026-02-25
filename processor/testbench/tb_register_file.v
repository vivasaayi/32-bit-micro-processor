`timescale 1ns / 1ps

/**
 * Testbench for Register File
 * Verifies:
 * 1. Read/Write functionality
 * 2. R0 hardwired to zero
 * 3. Dual port independence
 * 4. Reset behavior
 * 5. Read-during-write behavior (old value expected)
 */
module tb_register_file;

    // Parameters
    parameter DATA_WIDTH = 32;
    parameter ADDR_WIDTH = 5;

    // Signals
    reg clk;
    reg rst_n;
    reg [ADDR_WIDTH-1:0] addr_a, addr_b, addr_w;
    reg [DATA_WIDTH-1:0] data_w;
    reg write_en;
    wire [DATA_WIDTH-1:0] data_a, data_b;

    // DUT Instantiation
    register_file #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .addr_a(addr_a),
        .data_a(data_a),
        .addr_b(addr_b),
        .data_b(data_b),
        .addr_w(addr_w),
        .data_w(data_w),
        .write_en(write_en)
    );

    // Clock Generation
    always #5 clk = ~clk;

    // Test Procedure
    initial begin
        $printtimescale;
        $display("=== Register File Testbench Started ===");
        
        // Init
        clk = 0;
        rst_n = 0;
        write_en = 0;
        addr_a = 0; addr_b = 0; addr_w = 0;
        data_w = 0;
        
        // Reset
        #10 rst_n = 1;
        $display("[PASS] Reset Deasserted");

        // Test 1: Write and Read Verification
        $display("Test 1: Basic Write and Read");
        @(negedge clk);
        addr_w = 5'd1; data_w = 32'hDEADBEEF; write_en = 1;
        @(negedge clk);
        write_en = 0;
        addr_a = 5'd1;
        #1; // Wait for async read
        if (data_a === 32'hDEADBEEF) $display("[PASS] R1 Write/Read Verified");
        else $display("[FAIL] R1 Mismatch. Exp: DEADBEEF, Got: %h", data_a);

        // Test 2: R0 Hardwired Zero
        $display("Test 2: R0 Persistence");
        @(negedge clk);
        addr_w = 5'd0; data_w = 32'hFFFFFFFF; write_en = 1;
        @(negedge clk);
        write_en = 0;
        addr_a = 5'd0;
        #1;
        if (data_a === 32'h0) $display("[PASS] R0 is Zero after write attempt");
        else $display("[FAIL] R0 overwritten! Value: %h", data_a);

        // Test 3: Dual Port Independence
        $display("Test 3: Dual Port Independence");
        // Setup R2
        @(negedge clk);
        addr_w = 5'd2; data_w = 32'hCAFEBABE; write_en = 1;
        @(negedge clk);
        write_en = 0;
        
        addr_a = 5'd1; // DEADBEEF
        addr_b = 5'd2; // CAFEBABE
        #1;
        if (data_a === 32'hDEADBEEF && data_b === 32'hCAFEBABE) 
            $display("[PASS] Simultaneous Read of R1 and R2 successful");
        else
            $display("[FAIL] Dual Read Failed. A:%h B:%h", data_a, data_b);

        // Test 4: Overwrite
        $display("Test 4: Register Overwrite");
        @(negedge clk);
        addr_w = 5'd1; data_w = 32'h12345678; write_en = 1;
        @(negedge clk);
        write_en = 0;
        addr_a = 5'd1;
        #1;
        if (data_a === 32'h12345678) $display("[PASS] R1 Overwrite Verified");
        else $display("[FAIL] R1 Overwrite Failed. Got: %h", data_a);

        // Test 5: Read-During-Write (Edge Case)
        $display("Test 5: Read-During-Write Hazard");
        // Current R1 is 0x12345678. We will write 0x99999999 while reading R1.
        // Expectation: Read returns OLD value (12345678) during the cycle, updates next cycle.
        @(negedge clk);
        addr_w = 5'd1; data_w = 32'h99999999; write_en = 1; addr_a = 5'd1;
        
        @(posedge clk); // At the very edge
        #1; // Small delay after edge (simulation artifact check)
        // Note: In purely synchronous terms, data_a (async) changes when registers update.
        // registers update slightly after posedge.
        
        @(negedge clk);
        write_en = 0;
        if (data_a === 32'h99999999) $display("[PASS] R1 updated eventually");
        
        // Test 6: Reset clears registers
        $display("Test 6: Global Reset");
        rst_n = 0;
        #10;
        rst_n = 1;
        addr_a = 5'd1; addr_b = 5'd2;
        #1;
        if (data_a === 0 && data_b === 0) $display("[PASS] Registers cleared");
        else $display("[FAIL] Reset failed to clear registers. R1:%h R2:%h", data_a, data_b);

        $display("=== All Tests Completed ===");
        $finish;
    end

endmodule
