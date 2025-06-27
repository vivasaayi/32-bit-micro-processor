`timescale 1ns/1ps

module tb_simple;
    reg clk;
    reg rst_n;
    
    // Simple clock generation
    always #10 clk = ~clk;
    
    initial begin
        clk = 0;
        rst_n = 0;
        #100;
        rst_n = 1;
        
        $display("Simple testbench started");
        #1000;
        $display("Test completed");
        $finish;
    end
    
endmodule
