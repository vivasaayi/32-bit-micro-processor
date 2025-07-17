`timescale 1ns / 1ps

//
// Enhanced Microprocessor System with Display Support
// Includes CPU, memory, and display controller
//

module microprocessor_system_with_display (
    input wire clk,
    input wire reset,
    
    // VGA output
    output wire vga_hsync,
    output wire vga_vsync,
    output wire [7:0] vga_red,
    output wire [7:0] vga_green,
    output wire [7:0] vga_blue,
    output wire vga_blank,
    
    // Status LEDs
    output wire cpu_running,
    output wire display_active
);

    // Internal signals
    wire [31:0] cpu_addr;
    wire [31:0] cpu_write_data;
    wire [31:0] cpu_read_data;
    wire [31:0] memory_read_data;
    wire [31:0] display_read_data;
    wire cpu_write_enable;
    wire cpu_read_enable;
    wire [3:0] cpu_byte_enable;
    
    // Address decoding
    wire memory_select = (cpu_addr < 32'hFF000000);
    wire display_select = (cpu_addr >= 32'hFF000000);
    
    // Mux read data
    assign cpu_read_data = display_select ? display_read_data : memory_read_data;
    
    // CPU instance (simplified interface for now)
    // In a complete implementation, this would be your CPU core
    reg [31:0] pc;
    reg [31:0] instruction_memory [0:65535];
    
    // Simple CPU simulation for testing
    always @(posedge clk) begin
        if (reset) begin
            pc <= 32'h8000; // Start address
        end else begin
            // Very basic CPU simulation - just increment PC
            pc <= pc + 4;
        end
    end
    
    // Load program into instruction memory
    initial begin
        $readmemh("../output/simple_display_demo.hex", instruction_memory);
    end
    
    // Simple memory interface simulation
    assign cpu_addr = pc; // Simplified
    assign cpu_write_enable = 1'b1; // Simulate writes
    assign cpu_read_enable = 1'b1;
    assign cpu_byte_enable = 4'hF;
    assign cpu_write_data = 32'h12345678; // Test data
    
    // Main memory (simplified)
    reg [31:0] main_memory [0:16383]; // 64KB
    
    always @(posedge clk) begin
        if (memory_select && cpu_write_enable) begin
            main_memory[cpu_addr[15:2]] <= cpu_write_data;
        end
    end
    
    assign memory_read_data = memory_select ? main_memory[cpu_addr[15:2]] : 32'h0;
    
    // Display controller instance
    display_controller display (
        .clk(clk),
        .reset(reset),
        .addr(cpu_addr),
        .write_data(cpu_write_data),
        .read_data(display_read_data),
        .write_enable(display_select && cpu_write_enable),
        .read_enable(display_select && cpu_read_enable),
        .byte_enable(cpu_byte_enable),
        .vga_hsync(vga_hsync),
        .vga_vsync(vga_vsync),
        .vga_red(vga_red),
        .vga_green(vga_green),
        .vga_blue(vga_blue),
        .vga_blank(vga_blank),
        .display_ready(display_active),
        .frame_complete()
    );
    
    // Status outputs
    assign cpu_running = !reset;

endmodule
