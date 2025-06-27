/**
 * 32-bit Register File
 * 
 * 16 general-purpose 32-bit registers (R0-R15) with dual read ports
 * and one write port for the 32-bit microprocessor.
 * 
 * Features:
 * - 16 registers of 32 bits each (expanded from 8x8-bit)
 * - Dual read ports for ALU operations
 * - Single write port
 * - Synchronous write, asynchronous read
 * - R0 is hardwired to zero (common RISC convention)
 */

module register_file (
    input wire clk,
    input wire rst_n,
    
    // Read port A
    input wire [3:0] addr_a,        // 4-bit address for 16 registers
    output wire [31:0] data_a,      // 32-bit data output
    
    // Read port B  
    input wire [3:0] addr_b,        // 4-bit address for 16 registers
    output wire [31:0] data_b,      // 32-bit data output
    
    // Write port
    input wire [3:0] addr_w,        // 4-bit address for 16 registers
    input wire [31:0] data_w,       // 32-bit data input
    input wire write_en
);

    // Register array - 16 registers of 32 bits each
    reg [31:0] registers [1:15];    // R1-R15, R0 is hardwired to zero
    
    // Initialize registers
    integer i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 1; i < 16; i = i + 1) begin
                registers[i] <= 32'h00000000;
            end
        end else if (write_en && addr_w != 4'h0) begin
            // R0 cannot be written to (always zero)
            registers[addr_w] <= data_w;
        end
    end
    
    // Asynchronous read with R0 hardwired to zero
    assign data_a = (addr_a == 4'h0) ? 32'h00000000 : registers[addr_a];
    assign data_b = (addr_b == 4'h0) ? 32'h00000000 : registers[addr_b];

endmodule
