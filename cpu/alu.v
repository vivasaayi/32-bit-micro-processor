/**
 * 8-Bit ALU (Arithmetic Logic Unit)
 * 
 * Performs arithmetic and logic operations for the 8-bit microprocessor.
 * Supports all basic operations needed for a functional processor.
 * 
 * Operations supported:
 * - Arithmetic: ADD, SUB, ADC, SBC
 * - Logic: AND, OR, XOR, NOT
 * - Shift: SHL, SHR, ROL, ROR
 * - Compare: CMP
 */

module alu (
    input wire [7:0] a,         // First operand
    input wire [7:0] b,         // Second operand
    input wire [3:0] op,        // Operation code
    input wire [7:0] flags_in,  // Input flags
    output reg [7:0] result,    // Result
    output reg [7:0] flags_out  // Output flags
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
    reg [8:0] temp_result;  // 9-bit for carry detection
    reg carry_in;
    reg carry_out;
    reg zero_flag;
    reg negative_flag;
    reg overflow_flag;
    
    always @(*) begin
        // Default values
        result = 8'h00;
        flags_out = flags_in;
        temp_result = 9'h000;
        carry_in = flags_in[FLAG_CARRY];
        carry_out = 1'b0;
        zero_flag = 1'b0;
        negative_flag = 1'b0;
        overflow_flag = 1'b0;
        
        case (op)
            ALU_ADD: begin
                temp_result = a + b;
                result = temp_result[7:0];
                carry_out = temp_result[8];
                overflow_flag = (a[7] == b[7]) && (result[7] != a[7]);
            end
            
            ALU_SUB: begin
                temp_result = a - b;
                result = temp_result[7:0];
                carry_out = temp_result[8]; // Borrow
                overflow_flag = (a[7] != b[7]) && (result[7] != a[7]);
            end
            
            ALU_ADC: begin
                temp_result = a + b + carry_in;
                result = temp_result[7:0];
                carry_out = temp_result[8];
                overflow_flag = (a[7] == b[7]) && (result[7] != a[7]);
            end
            
            ALU_SBC: begin
                temp_result = a - b - carry_in;
                result = temp_result[7:0];
                carry_out = temp_result[8]; // Borrow
                overflow_flag = (a[7] != b[7]) && (result[7] != a[7]);
            end
            
            ALU_AND: begin
                result = a & b;
                carry_out = 1'b0; // Clear carry for logic operations
            end
            
            ALU_OR: begin
                result = a | b;
                carry_out = 1'b0;
            end
            
            ALU_XOR: begin
                result = a ^ b;
                carry_out = 1'b0;
            end
            
            ALU_NOT: begin
                result = ~a;
                carry_out = 1'b0;
            end
            
            ALU_SHL: begin
                result = {a[6:0], 1'b0};
                carry_out = a[7];
            end
            
            ALU_SHR: begin
                result = {1'b0, a[7:1]};
                carry_out = a[0];
            end
            
            ALU_ROL: begin
                result = {a[6:0], carry_in};
                carry_out = a[7];
            end
            
            ALU_ROR: begin
                result = {carry_in, a[7:1]};
                carry_out = a[0];
            end
            
            ALU_CMP: begin
                temp_result = a - b;
                result = a; // Don't change the register for compare
                carry_out = temp_result[8]; // Borrow
                overflow_flag = (a[7] != b[7]) && (temp_result[7] != a[7]);
            end
            
            ALU_PASS: begin
                result = a;
                carry_out = flags_in[FLAG_CARRY]; // Preserve carry
            end
            
            ALU_INC: begin
                temp_result = a + 1;
                result = temp_result[7:0];
                carry_out = temp_result[8];
                overflow_flag = (a == 8'h7F); // Overflow from 127 to 128
            end
            
            ALU_DEC: begin
                temp_result = a - 1;
                result = temp_result[7:0];
                carry_out = temp_result[8]; // Borrow
                overflow_flag = (a == 8'h80); // Overflow from -128 to 127
            end
            
            default: begin
                result = a;
                carry_out = flags_in[FLAG_CARRY];
            end
        endcase
        
        // Set flags
        zero_flag = (result == 8'h00);
        negative_flag = result[7];
        
        // Update flags register (preserve interrupt and user mode flags)
        flags_out[FLAG_CARRY] = carry_out;
        flags_out[FLAG_ZERO] = zero_flag;
        flags_out[FLAG_NEGATIVE] = negative_flag;
        flags_out[FLAG_OVERFLOW] = overflow_flag;
        // flags_out[FLAG_INTERRUPT] and flags_out[FLAG_USER] remain unchanged
    end
    
endmodule
