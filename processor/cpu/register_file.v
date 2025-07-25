/**
 * 32-bit Register File
 * 
 * 32 general-purpose 32-bit registers (R0-R31) with dual read ports
 * and one write port for the 32-bit microprocessor.
 * 
 * Features:
 * - 32 registers of 32 bits each (RISC-V style)
 * - Dual read ports for ALU operations
 * - Single write port
 * - Synchronous write, asynchronous read
 * - R0 is hardwired to zero (RISC convention)
 */

module register_file (
    input wire clk,
    input wire rst_n,
    
    // Read port A
    input wire [4:0] addr_a,        // 5-bit address for 32 registers
    output wire [31:0] data_a,      // 32-bit data output
    
    // Read port B  
    input wire [4:0] addr_b,        // 5-bit address for 32 registers
    output wire [31:0] data_b,      // 32-bit data output
    
    // Write port
    input wire [4:0] addr_w,        // 5-bit address for 32 registers
    input wire [31:0] data_w,       // 32-bit data input
    input wire write_en
);

    // Register array - 32 registers of 32 bits each
    reg [31:0] registers [1:31];    // R1-R31, R0 is hardwired to zero
    
    // Initialize registers
    integer i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            $display("[register_file] Reset: Clearing all registers to 0");
            for (i = 1; i < 32; i = i + 1) begin
                registers[i] <= 32'h00000000;
            end
        end else if (write_en && addr_w != 5'h0) begin
            // R0 cannot be written to (always zero)
            $display("[register_file] Write: R%0d <= 0x%08h", addr_w, data_w);
            registers[addr_w] <= data_w;
        end
    end
    
    // Asynchronous read with R0 hardwired to zero
    assign data_a = (addr_a == 5'h0) ? 32'h00000000 : registers[addr_a];
    assign data_b = (addr_b == 5'h0) ? 32'h00000000 : registers[addr_b];

    always @(*) begin
        $display("[register_file] Read: R%0d = 0x%08h (port A), R%0d = 0x%08h (port B)",
            addr_a, data_a, addr_b, data_b);
    end

    // Task to dump all register values
    task dump_regs;
        integer j;
        begin
            $display("[register_file] Register Dump:");
            for (j = 0; j < 32; j = j + 1) begin
                $display("REG[%0d] = 0x%08h", j, (j == 0) ? 32'h00000000 : registers[j]);
            end
        end
    endtask

endmodule
