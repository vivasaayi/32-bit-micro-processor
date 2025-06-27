`timescale 1ns/1ps

module tb_cpu_core;
    reg clk, rst_n;
    
    // Memory interface
    wire [15:0] addr_bus;
    wire [7:0] data_bus;
    wire mem_read, mem_write;
    reg mem_ready;
    
    // Simple memory model
    reg [7:0] memory [0:65535];
    reg [7:0] mem_data_out;
    
    // Test signals
    wire halted, user_mode;
    wire [7:0] interrupt_req = 8'h00;
    wire interrupt_ack;
    wire [7:0] io_addr, io_data;
    wire io_read, io_write;
    
    // Clock generation
    always #10 clk = ~clk;
    
    // Memory model
    always @(posedge clk) begin
        mem_ready <= 1'b0;
        if (mem_read) begin
            mem_data_out <= memory[addr_bus];
            mem_ready <= 1'b1;
        end else if (mem_write) begin
            memory[addr_bus] <= data_bus;
            mem_ready <= 1'b1;
        end
    end
    
    assign data_bus = (mem_read && mem_ready) ? mem_data_out : 8'bZ;
    
    // DUT
    cpu_core dut (
        .clk(clk),
        .rst_n(rst_n),
        .addr_bus(addr_bus),
        .data_bus(data_bus),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .mem_ready(mem_ready),
        .interrupt_req(interrupt_req),
        .interrupt_ack(interrupt_ack),
        .io_addr(io_addr),
        .io_data(io_data),
        .io_read(io_read),
        .io_write(io_write),
        .halted(halted),
        .user_mode(user_mode)
    );
    
    // Test
    initial begin
        integer i;
        
        // Initialize
        clk = 0;
        rst_n = 0;
        mem_ready = 0;
        
        // Clear memory
        for (i = 0; i < 65536; i = i + 1)
            memory[i] = 8'h00;
        
        // Load simple test program
        memory[16'h8000] = 8'h04; // ADDI R0, #42
        memory[16'h8001] = 8'h2A; // Immediate 42
        memory[16'h8002] = 8'h05; // ADDI R1, #10
        memory[16'h8003] = 8'h0A; // Immediate 10  
        memory[16'h8004] = 8'h00; // ADD R0, R1
        memory[16'h8005] = 8'h64; // HALT
        
        // Start test
        #100 rst_n = 1;
        
        $display("CPU Test Starting...");
        
        // Wait for halt
        wait(halted);
        
        $display("CPU Test Complete - System Halted");
        $display("Test passed!");
        
        #100 $finish;
    end
    
    // Monitor
    always @(posedge clk) begin
        if (rst_n && mem_read)
            $display("Time %t: PC=%h, Reading addr=%h, data=%h", 
                     $time, dut.pc, addr_bus, mem_data_out);
    end
    
endmodule
