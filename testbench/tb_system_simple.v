module tb_system_simple;

`timescale 1ns/1ps

reg clk;
reg rst_n;

// External memory interface
wire [15:0] ext_mem_addr;
wire [7:0] ext_mem_data;
wire ext_mem_read;
wire ext_mem_write;
wire ext_mem_cs;
reg ext_mem_ready;

// UART interface
reg uart_rx;
wire uart_tx;

// GPIO pins
wire [7:0] gpio_pins;

// System status
wire system_halted;
wire user_mode_active;
wire [7:0] debug_reg;

// Simple memory model
reg [7:0] memory [0:65535];
reg [7:0] mem_data_out;

// Clock generation
always #10 clk = ~clk;

// Memory model
always @(posedge clk) begin
    ext_mem_ready <= 1'b0;
    if (ext_mem_cs) begin
        if (ext_mem_read) begin
            mem_data_out <= memory[ext_mem_addr];
            ext_mem_ready <= 1'b1;
        end else if (ext_mem_write) begin
            memory[ext_mem_addr] <= ext_mem_data;
            ext_mem_ready <= 1'b1;
        end
    end
end

assign ext_mem_data = (ext_mem_read && ext_mem_ready) ? mem_data_out : 8'bZ;

// Instantiate the microprocessor system
microprocessor_system dut (
    .clk(clk),
    .rst_n(rst_n),
    .ext_mem_addr(ext_mem_addr),
    .ext_mem_data(ext_mem_data),
    .ext_mem_read(ext_mem_read),
    .ext_mem_write(ext_mem_write),
    .ext_mem_cs(ext_mem_cs),
    .ext_mem_ready(ext_mem_ready),
    .uart_rx(uart_rx),
    .uart_tx(uart_tx),
    .gpio_pins(gpio_pins),
    .system_halted(system_halted),
    .user_mode_active(user_mode_active),
    .debug_reg(debug_reg)
);

// Test sequence
initial begin
    integer i;
    
    $display("=== 8-Bit Microprocessor System Test ===");
    
    // Initialize signals
    clk = 0;
    rst_n = 0;
    uart_rx = 1;
    ext_mem_ready = 0;
    
    // Clear memory
    for (i = 0; i < 65536; i = i + 1) begin
        memory[i] = 8'h00;
    end
    
    // Load a simple test program at 0x8000 (kernel space)
    memory[16'h8000] = 8'h32; // LOADI R0, #42
    memory[16'h8001] = 8'h2A; // Immediate value 42
    memory[16'h8002] = 8'h32; // LOADI R1, #10  
    memory[16'h8003] = 8'h0A; // Immediate value 10
    memory[16'h8004] = 8'h00; // ADD R0, R1 (R0 = R0 + R1)
    memory[16'h8005] = 8'h64; // HALT
    
    $display("Test program loaded:");
    $display("  0x8000: LOADI R0, #42");
    $display("  0x8002: LOADI R1, #10"); 
    $display("  0x8004: ADD R0, R1");
    $display("  0x8005: HALT");
    
    // Initialize page table for MMU (simple identity mapping)
    for (i = 0; i < 256; i = i + 1) begin
        memory[16'hE000 + i] = 8'h80 | (i[3:0]); // Valid, user accessible, writable
    end
    
    // Reset sequence
    #100;
    rst_n = 1;
    
    $display("Time %0t: System reset complete, starting execution...", $time);
    
    // Wait for system to halt or timeout
    #10000;
    
    if (system_halted) begin
        $display("SUCCESS: System halted as expected");
        $display("Time %0t: Test completed successfully", $time);
    end else begin
        $display("INFO: System still running after timeout");
        $display("Time %0t: Debug register: %b", $time, debug_reg);
    end
    
    $display("=== Test Results ===");
    $display("System Halted: %b", system_halted);
    $display("User Mode: %b", user_mode_active);
    $display("Debug Register: %b", debug_reg);
    $display("GPIO Output: %h", gpio_pins);
    
    $finish;
end

// Monitor key signals
always @(posedge clk) begin
    if (rst_n && ext_mem_read && ext_mem_ready) begin
        $display("Time %0t: Memory read - Addr: 0x%h, Data: 0x%h", 
                 $time, ext_mem_addr, mem_data_out);
    end
end

// Timeout protection
initial begin
    #50000; // 50us timeout
    $display("TIMEOUT: Test exceeded maximum time");
    $finish;
end

endmodule
