/**
 * Register File
 * 
 * 8 general-purpose 8-bit registers (R0-R7) with dual read ports
 * and one write port for the 8-bit microprocessor.
 * 
 * Features:
 * - 8 registers of 8 bits each
 * - Dual read ports for ALU operations
 * - Single write port
 * - Synchronous write, asynchronous read
 */

module register_file (
    input wire clk,
    input wire rst_n,
    
    // Read port A
    input wire [2:0] addr_a,
    output wire [7:0] data_a,
    
    // Read port B  
    input wire [2:0] addr_b,
    output wire [7:0] data_b,
    
    // Write port
    input wire [2:0] addr_w,
    input wire [7:0] data_w,
    input wire write_en
);

    // Register array - 8 registers of 8 bits each
    reg [7:0] registers [0:7];
    
    // Initialize registers
    integer i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < 8; i = i + 1) begin
                registers[i] <= 8'h00;
            end
        end else if (write_en) begin
            registers[addr_w] <= data_w;
        end
    end
    
    // Asynchronous read
    assign data_a = registers[addr_a];
    assign data_b = registers[addr_b];
    
endmodule
