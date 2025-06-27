`timescale 1ns/1ps

module tb_minimal;
reg clk, rst_n;

always #10 clk = ~clk;

initial begin
    clk = 0;
    rst_n = 0;
    #100 rst_n = 1;
    $display("Test started");
    #1000;
    $display("Test finished");
    $finish;
end

endmodule
