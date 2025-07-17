`timescale 1ns / 1ps

module tb_jvm_test;

    // Testbench signals
    reg clk;
    reg reset;
    reg [31:0] instruction_memory [0:65535];
    reg [31:0] data_memory [0:65535];
    
    // CPU instance
    cpu_core cpu (
        .clk(clk),
        .reset(reset)
    );
    
    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    // Test sequence
    initial begin
        $display("=== JVM Test Bench ===");
        
        // Load JVM hex file
        $readmemh("../output/jvm_direct.hex", instruction_memory);
        
        // Initialize
        reset = 1;
        #20;
        reset = 0;
        
        // Run for a reasonable amount of time
        #10000;
        
        $display("JVM test completed");
        $finish;
    end
    
    // Monitor important signals
    always @(posedge clk) begin
        if (!reset) begin
            $display("Time: %0t, PC: %h", $time, cpu.pc);
        end
    end

endmodule
