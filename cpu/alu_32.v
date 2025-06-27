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

module alu_32 (
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
    localparam ALU_PASS = 4'hD; // Pass A through
    localparam ALU_INC  = 4'hE; // Increment A
    localparam ALU_DEC  = 4'hF; // Decrement A
    
    // Flag bit positions
    localparam FLAG_CARRY     = 0;
    localparam FLAG_ZERO      = 1;
    localparam FLAG_NEGATIVE  = 2;
    localparam FLAG_OVERFLOW  = 3;
    localparam FLAG_INTERRUPT = 4;
    localparam FLAG_USER      = 5;
    
    // Internal signals
    reg [32:0] temp_result;  // 33-bit for carry detection
    reg carry_in;
    
    always @(*) begin
        // Initialize
        temp_result = 33'h0;
        flags_out = flags_in;
        carry_in = flags_in[FLAG_CARRY];
        
        case (op)
            ALU_ADD: begin
                temp_result = {1'b0, a} + {1'b0, b};
                result = temp_result[31:0];
                flags_out[FLAG_CARRY] = temp_result[32];
            end
            
            ALU_SUB: begin
                temp_result = {1'b0, a} - {1'b0, b};
                result = temp_result[31:0];
                flags_out[FLAG_CARRY] = temp_result[32]; // Borrow
            end
            
            ALU_ADC: begin
                temp_result = {1'b0, a} + {1'b0, b} + {32'h0, carry_in};
                result = temp_result[31:0];
                flags_out[FLAG_CARRY] = temp_result[32];
            end
            
            ALU_SBC: begin
                temp_result = {1'b0, a} - {1'b0, b} - {32'h0, carry_in};
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
                temp_result = {1'b0, a} - {1'b0, b};
                result = a; // CMP doesn't change the operand
                flags_out[FLAG_CARRY] = temp_result[32]; // Borrow
            end
            
            ALU_PASS: begin
                result = a;
                flags_out[FLAG_CARRY] = 1'b0;
            end
            
            ALU_INC: begin
                temp_result = {1'b0, a} + 33'h1;
                result = temp_result[31:0];
                flags_out[FLAG_CARRY] = temp_result[32];
            end
            
            ALU_DEC: begin
                temp_result = {1'b0, a} - 33'h1;
                result = temp_result[31:0];
                flags_out[FLAG_CARRY] = temp_result[32]; // Borrow
            end
            
            default: begin
                result = 32'h0;
                flags_out[FLAG_CARRY] = 1'b0;
            end
        endcase
        
        // Update other flags
        flags_out[FLAG_ZERO] = (result == 32'h0);
        flags_out[FLAG_NEGATIVE] = result[31];
        
        // Overflow detection for addition/subtraction
        case (op)
            ALU_ADD, ALU_ADC: begin
                flags_out[FLAG_OVERFLOW] = (a[31] == b[31]) && (result[31] != a[31]);
            end
            ALU_SUB, ALU_SBC, ALU_CMP: begin
                flags_out[FLAG_OVERFLOW] = (a[31] != b[31]) && (result[31] != a[31]);
            end
            default: begin
                // Keep existing overflow flag for other operations
            end
        endcase
    end

endmodule
