/**
 * 32-bit Register File (RISC-V RV32I)
 * 
 * Implements the base integer ISA register state with 32 x registers (x0-x31),
 * each 32 bits wide (XLEN=32). Register x0 is hardwired with all bits equal to 0.
 * General purpose registers x1–x31 hold values that various instructions interpret
 * as a collection of Boolean values, or as two’s complement signed binary integers
 * or unsigned binary integers.
 * 
 * Standard calling convention:
 * - x1: return address for calls (link register)
 * - x2: stack pointer
 * - x5: alternate link register
 * 
 * Features:
 * - 32 registers of 32 bits each (RISC-V style)
 * - Dual read ports for ALU operations
 * - Single write port
 * - Synchronous write, asynchronous read
 * - x0 is hardwired to zero (RISC-V convention)
 */

module register_file #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 5
) (
    input wire clk,
    input wire rst_n,
    
    // Read port A
    input wire [ADDR_WIDTH-1:0] addr_a,    // Address for port A
    output wire [DATA_WIDTH-1:0] data_a,   // Data output A
    
    // Read port B  
    input wire [ADDR_WIDTH-1:0] addr_b,    // Address for port B
    output wire [DATA_WIDTH-1:0] data_b,   // Data output B
    
    // Write port
    input wire [ADDR_WIDTH-1:0] addr_w,    // Write address
    input wire [DATA_WIDTH-1:0] data_w,    // Data input
    input wire write_en
);

    // Register array - Stores x1 to x(2^ADDR_WIDTH - 1)
    // x0 is hardwired to zero and not stored to save area
    reg [DATA_WIDTH-1:0] registers [1:(1<<ADDR_WIDTH)-1];
    
    integer i;
    
    // Synchronous Write Logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            `ifdef DEBUG
            $display("[register_file] Reset: Clearing all registers to 0");
            `endif
            for (i = 1; i < (1<<ADDR_WIDTH); i = i + 1) begin
                registers[i] <= {DATA_WIDTH{1'b0}};
            end
        end else if (write_en && addr_w != {ADDR_WIDTH{1'b0}}) begin
            // Write only if write enable is high and not writing to x0
            `ifdef DEBUG
            $display("[register_file] Write: x%0d <= 0x%h", addr_w, data_w);
            `endif
            registers[addr_w] <= data_w;
        end
    end
    
    // Asynchronous Read Logic
    // If address is 0, return 0, otherwise read from array
    assign data_a = (addr_a == {ADDR_WIDTH{1'b0}}) ? {DATA_WIDTH{1'b0}} : registers[addr_a];
    assign data_b = (addr_b == {ADDR_WIDTH{1'b0}}) ? {DATA_WIDTH{1'b0}} : registers[addr_b];

    // Debug monitoring (simulation only)
`ifdef DEBUG
    always @(*) begin
        $display("[register_file] Read: x%0d = 0x%h (port A), x%0d = 0x%h (port B)",
            addr_a, data_a, addr_b, data_b);
    end
`endif

    // Task to dump all register values
    task dump_regs;
        integer j;
        begin
            $display("[register_file] Register Dump:");
            $display("x[0] = 0x%h (Hardwired)", {DATA_WIDTH{1'b0}});
            for (j = 1; j < (1<<ADDR_WIDTH); j = j + 1) begin
                $display("x[%0d] = 0x%h", j, registers[j]);
            end
        end
    endtask

endmodule
