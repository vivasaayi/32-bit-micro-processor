// alu_tb.v - Comprehensive testbench for 32-bit ALU
//
// Tests all ALU operations, edge cases, and flag behaviors.

`timescale 1ns/1ps

module alu_tb;
    reg [31:0] a, b;
    reg [6:0] opcode;
    reg [2:0] funct3;
    reg [6:0] funct7;
    reg [7:0] flags_in;
    wire [31:0] result;
    wire [7:0] flags_out;

    integer i;

    // Instantiate the ALU
    alu uut (
        .a(a),
        .b(b),
        .opcode(opcode),
        .funct3(funct3),
        .funct7(funct7),
        .flags_in(flags_in),
        .result(result),
        .flags_out(flags_out)
    );

    // RISC-V Opcodes
    localparam OP_REG = 7'h33;
    localparam OP_IMM = 7'h13;

    // Flag bit positions
    localparam FLAG_CARRY    = 0;
    localparam FLAG_ZERO     = 1;
    localparam FLAG_NEGATIVE = 2;
    localparam FLAG_OVERFLOW = 3;

    // Helper task for checking results
    task check;
        input [31:0] exp_result;
        input [7:0] exp_flags;
        input [255:0] msg;
        begin
            #1;
            if (result !== exp_result || flags_out !== exp_flags) begin
                $display("FAIL: %s | a=0x%h (%0d) b=0x%h (%0d) opcode=0x%h funct3=0x%h funct7=0x%h result=0x%h (%0d) (exp 0x%h (%0d)) flags=%b (exp %b)",
                    msg, a, a, b, b, opcode, funct3, funct7, result, result, exp_result, exp_result, flags_out, exp_flags);
            end else begin
                $display("PASS: %s | a=0x%h (%0d) b=0x%h (%0d) opcode=0x%h funct3=0x%h funct7=0x%h result=0x%h (%0d) flags=%b",
                    msg, a, a, b, b, opcode, funct3, funct7, result, result, flags_out);
            end
        end
    endtask

    initial begin
        $display("Starting ALU tests...");
        flags_in = 8'b0;

        // ----------------------
        // ADDITION TESTS (R-type ADD)
        // ----------------------
        // Test: 10 + 5 = 15
        a = 32'd10; b = 32'd5; opcode = OP_REG; funct3 = 3'h0; funct7 = 7'h00;
        #1; check(32'd15, 8'b00000000, "ADD basic");

        // Test: 22 + 133 = 155
        a = 32'd22; b = 32'd133; opcode = OP_REG; funct3 = 3'h0; funct7 = 7'h00;
        #1; check(32'd155, 8'b00000000, "ADD basic");

        // Test: 0 + 0 = 0
        a = 32'd0; b = 32'd0; opcode = OP_REG; funct3 = 3'h0; funct7 = 7'h00;
        #1; check(32'd0, 8'b00000000, "ADD basic");

        // Test: 0 + 99 = 0
        a = 32'd0; b = 32'd99; opcode = OP_REG; funct3 = 3'h0; funct7 = 7'h00;
        #1; check(32'd99, 8'b00000000, "ADD basic");

        // Test: 144 + 0 = 0
        a = 32'd144; b = 32'd0; opcode = OP_REG; funct3 = 3'h0; funct7 = 7'h00;
        #1; check(32'd144, 8'b00000000, "ADD basic");
        
        // Test: 0xFFFFFFFF (4294967295) + 1 = 0 (overflow, zero)
        a = 32'hFFFFFFFF; b = 32'd1; opcode = OP_REG; funct3 = 3'h0; funct7 = 7'h00;
        #1; check(32'd0, 8'b00000011, "ADD overflow+zero");
        
        // Test: 0x7FFFFFFF + 1 = 0x80000000 (signed overflow)
        a = 32'h7FFFFFFF; b = 32'd1; opcode = OP_REG; funct3 = 3'h0; funct7 = 7'h00;
        #1; check(32'h80000000, 8'b00001000, "ADD signed overflow");
        
        // Test: 0x80000000 + 0xFFFFFFFF = 0x7FFFFFFF (no overflow, carry set)
        a = 32'h80000000; b = 32'hFFFFFFFF; opcode = OP_REG; funct3 = 3'h0; funct7 = 7'h00;
        #1; check(32'h7FFFFFFF, 8'b00000001, "ADD min neg + -1");

        // ----------------------
        // SUBTRACTION TESTS (R-type SUB)
        // ----------------------
        // Test: 10 - 5 = 5 (decimal: 10 - 4 = 6)
        a = 32'd10; b = 32'd4; opcode = OP_REG; funct3 = 3'h0; funct7 = 7'h20;
        #1; check(32'd6, 8'b00000000, "SUB basic");
        // Test: 0 - 1 = 0xFFFFFFFF (decimal: 0 - 1 = -1)
        a = 32'd0; b = 32'd1; opcode = OP_REG; funct3 = 3'h0; funct7 = 7'h20;
        #1; check(32'hFFFFFFFF, 8'b00000101, "SUB negative");
        // Test: 0 - 0 = 0 (zero flag set)
        a = 32'd0; b = 32'd0; opcode = OP_REG; funct3 = 3'h0; funct7 = 7'h20;
        #1; check(32'd0, 8'b00000010, "SUB zero");
        // Test: 1 - 2 = 0xFFFFFFFF (negative, carry set)
        a = 32'd1; b = 32'd2; opcode = OP_REG; funct3 = 3'h0; funct7 = 7'h20;
        #1; check(32'hFFFFFFFF, 8'b00000101, "SUB underflow");

        // ----------------------
        // AND TESTS (R-type AND)
        // ----------------------
        // Test: 0xF0F0F0F0 (4042322160) & 0x0F0F0F0F (252645135) = 0
        a = 32'hF0F0F0F0; b = 32'h0F0F0F0F; opcode = OP_REG; funct3 = 3'h7; funct7 = 7'h00;
        #1; check(32'h00000000, 8'b00000010, "AND zero");
        // Test: 0xFFFFFFFF & 0x12345678 = 0x12345678
        a = 32'hFFFFFFFF; b = 32'h12345678; opcode = OP_REG; funct3 = 3'h7; funct7 = 7'h00;
        #1; check(32'h12345678, 8'b00000000, "AND all ones");

        // ----------------------
        // OR TESTS (R-type OR)
        // ----------------------
        // Test: 0xF0F0F0F0 (4042322160) | 0x0F0F0F0F (252645135) = 0xFFFFFFFF (4294967295)
        a = 32'hF0F0F0F0; b = 32'h0F0F0F0F; opcode = OP_REG; funct3 = 3'h6; funct7 = 7'h00;
        #1; check(32'hFFFFFFFF, 8'b00000100, "OR all ones");
        // Test: 0x0 | 0xABCDEF01 = 0xABCDEF01
        a = 32'h0; b = 32'hABCDEF01; opcode = OP_REG; funct3 = 3'h6; funct7 = 7'h00;
        #1; check(32'hABCDEF01, 8'b00001000, "OR with zero");

        // ----------------------
        // XOR TESTS (R-type XOR)
        // ----------------------
        // Test: 0xFF00FF00 (4278255360) ^ 0x00FF00FF (16711935) = 0xFFFFFFFF (4294967295)
        a = 32'hFF00FF00; b = 32'h00FF00FF; opcode = OP_REG; funct3 = 3'h4; funct7 = 7'h00;
        #1; check(32'hFFFFFFFF, 8'b00000100, "XOR all ones");



        // ----------------------
        // SHIFT LEFT TESTS (R-type SLL)
        // ----------------------
        // Test: 1 << 1 = 2 (decimal: 1 << 1 = 2)
        a = 32'h00000001; b = 1; opcode = OP_REG; funct3 = 3'h1; funct7 = 7'h00;
        #1; check(32'h00000002, 8'b00000000, "SLL by 1");
        // Test: 0x80000000 << 1 = 0x00000000 (carry set, zero flag set)
        a = 32'h80000000; b = 1; opcode = OP_REG; funct3 = 3'h1; funct7 = 7'h00;
        #1; check(32'h00000000, 8'b00000011, "SLL high bit");

        // ----------------------
        // SHIFT RIGHT TESTS (R-type SRL)
        // ----------------------
        // Test: 0x80000000 (2147483648) >> 1 = 0x40000000 (1073741824)
        a = 32'h80000000; b = 1; opcode = OP_REG; funct3 = 3'h5; funct7 = 7'h00;
        #1; check(32'h40000000, 8'b00000000, "SRL by 1");
        // Test: 0x00000003 >> 1 = 0x00000001 (carry set)
        a = 32'h00000003; b = 1; opcode = OP_REG; funct3 = 3'h5; funct7 = 7'h00;
        #1; check(32'h00000001, 8'b00000001, "SRL odd value");

        // ----------------------
        // ARITHMETIC SHIFT RIGHT TESTS (R-type SRA)
        // ----------------------
        // Test: 0xF0000000 (decimal: -268435456) >>> 4 = 0xFF000000 (decimal: -16777216)
        a = 32'hF0000000; b = 4; opcode = OP_REG; funct3 = 3'h5; funct7 = 7'h20;
        #1; check(32'hFF000000, 8'b00000100, "SRA negative");

        // ----------------------
        // I-TYPE TESTS
        // ----------------------
        // Test: ADDI 10 + 5 = 15
        a = 32'd10; b = 32'd5; opcode = OP_IMM; funct3 = 3'h0; funct7 = 7'h00;
        #1; check(32'd15, 8'b00000000, "ADDI basic");

        // Test: SLTI 10 < 5 = 0
        a = 32'd10; b = 32'd5; opcode = OP_IMM; funct3 = 3'h2; funct7 = 7'h00;
        #1; check(32'd0, 8'b00000000, "SLTI false");

        // Test: SLTI 5 < 10 = 1
        a = 32'd5; b = 32'd10; opcode = OP_IMM; funct3 = 3'h2; funct7 = 7'h00;
        #1; check(32'd1, 8'b00000000, "SLTI true");

        // Test: SLLI 1 << 1 = 2
        a = 32'd1; b = 32'd1; opcode = OP_IMM; funct3 = 3'h1; funct7 = 7'h00;
        #1; check(32'd2, 8'b00000000, "SLLI basic");

        // Test: SRLI 4 >> 1 = 2
        a = 32'd4; b = 32'd1; opcode = OP_IMM; funct3 = 3'h5; funct7 = 7'h00;
        #1; check(32'd2, 8'b00000000, "SRLI basic");

        // Test: SRAI -4 >>> 1 = -2
        a = -32'd4; b = 32'd1; opcode = OP_IMM; funct3 = 3'h5; funct7 = 7'h20;
        #1; check(-32'd2, 8'b00000100, "SRAI negative");

        $display("ALU tests complete.");
        $finish;
    end
endmodule
