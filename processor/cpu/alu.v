/**
 * 32-Bit ALU (Arithmetic Logic Unit)
 * 
 * Performs arithmetic and logic operations for the 32-bit microprocessor.
 * Supports all basic operations needed for a functional processor.
 * 
 * Operations supported:
 * - Arithmetic: ADD, SUB, ADC, SBC
 * - Logic: AND, OR, XOR, NOT
 * - Shift: SHL, SHR, ROL, ROR
 * - Compare: CMP
 * - 32-bit specific: MUL (multiply), DIV (divide)
 */

module alu (
    input wire [31:0] a,         // First operand (32-bit)
    input wire [31:0] b,         // Second operand (32-bit)
    input wire [3:0] op,         // Operation code
    input wire [7:0] flags_in,   // Input flags
    output reg [31:0] result,    // Result (32-bit)
    output reg [7:0] flags_out   // Output flags
);

    // ALU operation codes
    localparam ALU_ADD  = 4'h0;
    localparam ALU_SUB  = 4'h1;
    localparam ALU_ADC  = 4'h2;
    localparam ALU_SBC  = 4'h3;
    localparam ALU_AND  = 4'h4;
    localparam ALU_OR   = 4'h5;
    localparam ALU_XOR  = 4'h6;
    localparam ALU_NOT  = 4'h7;
    localparam ALU_SHL  = 4'h8;
    localparam ALU_SHR  = 4'h9;
    localparam ALU_ROL  = 4'hA;
    localparam ALU_ROR  = 4'hB;
    localparam ALU_CMP  = 4'hC;
    localparam ALU_PASS = 4'hD;
    localparam ALU_MUL  = 4'hE;  // Multiply
    localparam ALU_DIV  = 4'hF;  // Divide

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
    reg [3:0] debug_op;
    
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
                $display("DEBUG ALU ADD: a=%0d b=%0d result=%0d", operand_a, operand_b, result);
            end
            
            ALU_SUB: begin
                temp_result = {1'b0, operand_a} - {1'b0, operand_b};
                result = temp_result[31:0];
                flags_out[FLAG_CARRY] = temp_result[32];
                flags_out[FLAG_OVERFLOW] = (operand_a[31] != operand_b[31]) && (result[31] != operand_a[31]);
            end
            
            ALU_ADC: begin
                temp_result = {1'b0, operand_a} + {1'b0, operand_b} + {32'h0, carry_in};
                result = temp_result[31:0];
                flags_out[FLAG_CARRY] = temp_result[32];
            end
            
            ALU_SBC: begin
                temp_result = {1'b0, operand_a} - {1'b0, operand_b} - {32'h0, carry_in};
                result = temp_result[31:0];
                flags_out[FLAG_CARRY] = temp_result[32]; // Borrow
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
            
            ALU_ROL: begin
                result = {a[30:0], carry_in};
                flags_out[FLAG_CARRY] = a[31];
            end
            
            ALU_ROR: begin
                result = {carry_in, a[31:1]};
                flags_out[FLAG_CARRY] = a[0];
            end
            
            ALU_CMP: begin
                temp_result = {1'b0, operand_a} - {1'b0, operand_b};
                result = a; // CMP doesn't change the operand
                flags_out[FLAG_CARRY] = temp_result[32]; // Borrow
            end
            
            ALU_PASS: begin
                result = a;
                flags_out[FLAG_CARRY] = 1'b0;
            end
            
            ALU_MUL: begin
                // 32-bit multiplication (lower 32 bits of result)
                result = operand_a * operand_b;
                flags_out[FLAG_CARRY] = 1'b0; // Simplified - could detect overflow
            end
            
            ALU_DIV: begin
                // 32-bit division (quotient)
                if (operand_b != 0) begin
                    result = operand_a / operand_b;
                    flags_out[FLAG_CARRY] = 1'b0;
                end else begin
                    result = 32'hFFFFFFFF; // Division by zero
                    flags_out[FLAG_CARRY] = 1'b1;
                end
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
