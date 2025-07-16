/**
 * 32-Bit ALU (Arithmetic Logic Unit)
 * 
 * Performs arithmetic and logic operations for the 32-bit microprocessor.
 * Supports all basic operations needed for a functional processor.
 *
 * ALU OPCODE TABLE (0x00–0x1F)
 * | Opcode | Mnemonic | Operation         |
 * |--------|----------|------------------|
 * | 0x00   | ADD      | a + b            |
 * | 0x01   | SUB      | a - b            |
 * | 0x02   | AND      | a & b            |
 * | 0x03   | OR       | a | b            |
 * | 0x04   | XOR      | a ^ b            |
 * | 0x05   | NOT      | ~a               |
 * | 0x06   | SHL      | a << b           |
 * | 0x07   | SHR      | a >> b           |
 * | 0x08   | MUL      | a * b            |
 * | 0x09   | DIV      | a / b            |
 * | 0x0A   | MOD      | a % b            |
 * | 0x0B   | CMP      | compare a, b     |
 * | 0x0C   | SAR      | a >>> b (arith)  |
 * | 0x0D   | ADDI     | a + immediate    |
 * | 0x0E   | SUBI     | a - immediate    |
 * ---------------------------------------------------
 */

module alu (
    input wire [31:0] a,         // First operand (32-bit)
    input wire [31:0] b,         // Second operand (32-bit)
    input wire [5:0] op,         // Operation code (6-bit, matches CPU)
    input wire [7:0] flags_in,   // Input flags
    output reg [31:0] result,    // Result (32-bit)
    output reg [7:0] flags_out   // Output flags
);

    // ALU operation codes (0x00–0x1F, matches cpu_core.v)
    localparam ALU_ADD  = 6'h00;
    localparam ALU_SUB  = 6'h01;
    localparam ALU_AND  = 6'h02;
    localparam ALU_OR   = 6'h03;
    localparam ALU_XOR  = 6'h04;
    localparam ALU_NOT  = 6'h05;
    localparam ALU_SHL  = 6'h06;
    localparam ALU_SHR  = 6'h07;
    localparam ALU_MUL  = 6'h08;
    localparam ALU_DIV  = 6'h09;
    localparam ALU_MOD  = 6'h0A;
    localparam ALU_CMP  = 6'h0B;
    localparam ALU_SAR  = 6'h0C;
    localparam ALU_ADDI = 6'h0D;
    localparam ALU_SUBI = 6'h0E;

    // Flag bit positions
    localparam FLAG_CARRY     = 0;
    localparam FLAG_ZERO      = 1;
    localparam FLAG_NEGATIVE  = 2;
    localparam FLAG_OVERFLOW  = 3;
    
    // Internal signals for proper arithmetic
    reg [32:0] temp_result;  // 33-bit for carry detection
    reg carry_in;
    reg [31:0] operand_a;
    reg [31:0] operand_b;
    
    // Debug signals
    reg [5:0] debug_op;
    
    always @(*) begin
        // Initialize
        operand_a = a;
        operand_b = b;
        temp_result = 33'h0;
        flags_out = flags_in;
        carry_in = flags_in[FLAG_CARRY];
        debug_op = op;
        
        case (op)
            ALU_ADD: begin
                temp_result = {1'b0, operand_a} + {1'b0, operand_b};
                result = temp_result[31:0];
                flags_out[FLAG_CARRY] = temp_result[32];
                flags_out[FLAG_OVERFLOW] = (operand_a[31] == operand_b[31]) && (result[31] != operand_a[31]);
                // $display("DEBUG ALU ADD: a=%0d b=%0d result=%0d", operand_a, operand_b, result);
            end
            ALU_ADDI: begin
                temp_result = {1'b0, operand_a} + {1'b0, operand_b};
                result = temp_result[31:0];
                flags_out[FLAG_CARRY] = temp_result[32];
                flags_out[FLAG_OVERFLOW] = (operand_a[31] == operand_b[31]) && (result[31] != operand_a[31]);
                // $display("DEBUG ALU ADDI: a=%0d b=%0d result=%0d", operand_a, operand_b, result);
            end
            ALU_SUB: begin
                temp_result = {1'b0, operand_a} - {1'b0, operand_b};
                result = temp_result[31:0];
                flags_out[FLAG_CARRY] = temp_result[32];
                flags_out[FLAG_OVERFLOW] = (operand_a[31] != operand_b[31]) && (result[31] != operand_a[31]);
            end
            ALU_SUBI: begin
                temp_result = {1'b0, operand_a} - {1'b0, operand_b};
                result = temp_result[31:0];
                flags_out[FLAG_CARRY] = temp_result[32];
                flags_out[FLAG_OVERFLOW] = (operand_a[31] != operand_b[31]) && (result[31] != operand_a[31]);
                // $display("DEBUG ALU SUBI: a=%0d b=%0d result=%0d", operand_a, operand_b, result);
            end
            ALU_AND: begin
                result = a & b;
                flags_out[FLAG_CARRY] = 1'b0;
            end
            ALU_OR: begin
                result = a | b;
                flags_out[FLAG_CARRY] = 1'b0;
            end
            ALU_XOR: begin
                result = a ^ b;
                flags_out[FLAG_CARRY] = 1'b0;
            end
            ALU_NOT: begin
                result = ~a;
                flags_out[FLAG_CARRY] = 1'b0;
            end
            ALU_SHL: begin
                temp_result = {a, 1'b0};
                result = temp_result[31:0];
                flags_out[FLAG_CARRY] = temp_result[32];
            end
            ALU_SHR: begin
                result = {1'b0, a[31:1]};
                flags_out[FLAG_CARRY] = a[0];
            end
            ALU_SAR: begin
                result = $signed(a) >>> b;
                flags_out[FLAG_CARRY] = a[0];
            end
            ALU_MUL: begin
                result = operand_a * operand_b;
                flags_out[FLAG_CARRY] = 1'b0;
            end
            ALU_DIV: begin
                if (operand_b != 0) begin
                    result = operand_a / operand_b;
                    flags_out[FLAG_CARRY] = 1'b0;
                end else begin
                    result = 32'hFFFFFFFF;
                    flags_out[FLAG_CARRY] = 1'b1;
                end
            end
            ALU_MOD: begin
                if (operand_b != 0) begin
                    result = operand_a % operand_b;
                    flags_out[FLAG_CARRY] = 1'b0;
                end else begin
                    result = 32'h0;
                    flags_out[FLAG_CARRY] = 1'b1;
                end
            end
            ALU_CMP: begin
                temp_result = {1'b0, operand_a} - {1'b0, operand_b};
                result = a;
                flags_out[FLAG_CARRY] = temp_result[32];
            end
            default: begin
                result = 32'h0;
                flags_out[FLAG_CARRY] = 1'b0;
            end
        endcase
        
        // Update other flags
        flags_out[FLAG_ZERO] = (result == 32'h0);
        flags_out[FLAG_NEGATIVE] = result[31];
    end

endmodule
