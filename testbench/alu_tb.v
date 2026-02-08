// alu_tb.v - Comprehensive testbench for 32-bit ALU
//
// Tests all ALU operations, edge cases, and flag behaviors.

`timescale 1ns/1ps

module alu_tb;
    reg [31:0] a, b;
    reg [5:0] op;
    reg [7:0] flags_in;
    wire [31:0] result;
    wire [7:0] flags_out;

    integer i;

    // Instantiate the ALU
    alu uut (
        .a(a),
        .b(b),
        .op(op),
        .flags_in(flags_in),
        .result(result),
        .flags_out(flags_out)
    );

    // ALU opcodes (must match alu.v)
    localparam ALU_ADD = 6'h00;
    localparam ALU_SUB = 6'h01;
    localparam ALU_AND = 6'h02;
    localparam ALU_OR  = 6'h03;
    localparam ALU_XOR = 6'h04;
    localparam ALU_NOT = 6'h05;
    localparam ALU_SHL = 6'h06;
    localparam ALU_SHR = 6'h07;
    localparam ALU_MUL = 6'h08;
    localparam ALU_DIV = 6'h09;
    localparam ALU_MOD = 6'h0A;
    localparam ALU_CMP = 6'h0B;
    localparam ALU_SAR = 6'h0C;

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
                $display("FAIL: %s | a=0x%h (%0d) b=0x%h (%0d) op=0x%h result=0x%h (%0d) (exp 0x%h (%0d)) flags=%b (exp %b)",
                    msg, a, a, b, b, op, result, result, exp_result, exp_result, flags_out, exp_flags);
            end else begin
                $display("PASS: %s | a=0x%h (%0d) b=0x%h (%0d) op=0x%h result=0x%h (%0d) flags=%b",
                    msg, a, a, b, b, op, result, result, flags_out);
            end
        end
    endtask

    initial begin
        $display("Starting ALU tests...");
        flags_in = 8'b0;

        // ----------------------
        // ADDITION TESTS
        // ----------------------
        // Test: 10 + 5 = 15
        a = 32'd10; b = 32'd5; op = ALU_ADD;
        #1; check(32'd15, 8'b00000000, "ADD basic");

        // Test: 22 + 133 = 155
        a = 32'd22; b = 32'd133; op = ALU_ADD;
        #1; check(32'd155, 8'b00000000, "ADD basic");

        // Test: 0 + 0 = 0
        a = 32'd0; b = 32'd0; op = ALU_ADD;
        #1; check(32'd0, 8'b00000000, "ADD basic");

        // Test: 0 + 99 = 0
        a = 32'd0; b = 32'd99; op = ALU_ADD;
        #1; check(32'd99, 8'b00000000, "ADD basic");

        // Test: 144 + 0 = 0
        a = 32'd144; b = 32'd0; op = ALU_ADD;
        #1; check(32'd144, 8'b00000000, "ADD basic");
        
        // Test: 0xFFFFFFFF (4294967295) + 1 = 0 (overflow, zero)
        a = 32'hFFFFFFFF; b = 32'd1; op = ALU_ADD;
        #1; check(32'd0, 8'b00000011, "ADD overflow+zero");
        
        // Test: 0x7FFFFFFF + 1 = 0x80000000 (signed overflow)
        a = 32'h7FFFFFFF; b = 32'd1; op = ALU_ADD;
        #1; check(32'h80000000, 8'b00001000, "ADD signed overflow");
        
        // Test: 0x80000000 + 0xFFFFFFFF = 0x7FFFFFFF (no overflow, carry set)
        a = 32'h80000000; b = 32'hFFFFFFFF; op = ALU_ADD;
        #1; check(32'h7FFFFFFF, 8'b00000001, "ADD min neg + -1");

        // ----------------------
        // SUBTRACTION TESTS
        // ----------------------
        // Test: 10 - 5 = 5 (decimal: 10 - 4 = 6)
        a = 32'd10; b = 32'd4; op = ALU_SUB;
        #1; check(32'd6, 8'b00000000, "SUB basic");
        // Test: 0 - 1 = 0xFFFFFFFF (decimal: 0 - 1 = -1)
        a = 32'd0; b = 32'd1; op = ALU_SUB;
        #1; check(32'hFFFFFFFF, 8'b00000101, "SUB negative");
        // Test: 0 - 0 = 0 (zero flag set)
        a = 32'd0; b = 32'd0; op = ALU_SUB;
        #1; check(32'd0, 8'b00000010, "SUB zero");
        // Test: 1 - 2 = 0xFFFFFFFF (negative, carry set)
        a = 32'd1; b = 32'd2; op = ALU_SUB;
        #1; check(32'hFFFFFFFF, 8'b00000101, "SUB underflow");

        // ----------------------
        // AND TESTS
        // ----------------------
        // Test: 0xF0F0F0F0 (4042322160) & 0x0F0F0F0F (252645135) = 0
        a = 32'hF0F0F0F0; b = 32'h0F0F0F0F; op = ALU_AND;
        #1; check(32'h00000000, 8'b00000010, "AND zero");
        // Test: 0xFFFFFFFF & 0x12345678 = 0x12345678
        a = 32'hFFFFFFFF; b = 32'h12345678; op = ALU_AND;
        #1; check(32'h12345678, 8'b00000000, "AND all ones");

        // ----------------------
        // OR TESTS
        // ----------------------
        // Test: 0xF0F0F0F0 (4042322160) | 0x0F0F0F0F (252645135) = 0xFFFFFFFF (4294967295)
        a = 32'hF0F0F0F0; b = 32'h0F0F0F0F; op = ALU_OR;
        #1; check(32'hFFFFFFFF, 8'b00000100, "OR all ones");
        // Test: 0x0 | 0xABCDEF01 = 0xABCDEF01
        a = 32'h0; b = 32'hABCDEF01; op = ALU_OR;
        #1; check(32'hABCDEF01, 8'b00001000, "OR with zero");

        // ----------------------
        // XOR TESTS
        // ----------------------
        // Test: 0xFF00FF00 (4278255360) ^ 0x00FF00FF (16711935) = 0xFFFFFFFF (4294967295)
        a = 32'hFF00FF00; b = 32'h00FF00FF; op = ALU_XOR;
        #1; check(32'hFFFFFFFF, 8'b00000100, "XOR all ones");

        // ----------------------
        // NOT TESTS
        // ----------------------
        // Test: ~0 = 0xFFFFFFFF (decimal: ~0 = -1)
        a = 32'h00000000; op = ALU_NOT;
        #1; check(32'hFFFFFFFF, 8'b00000100, "NOT zero");

        // ----------------------
        // SHIFT LEFT TESTS
        // ----------------------
        // Test: 1 << 1 = 2 (decimal: 1 << 1 = 2)
        a = 32'h00000001; b = 1; op = ALU_SHL;
        #1; check(32'h00000002, 8'b00000000, "SHL by 1");
        // Test: 0x80000000 << 1 = 0x00000000 (carry set, zero flag set)
        a = 32'h80000000; b = 1; op = ALU_SHL;
        #1; check(32'h00000000, 8'b00000011, "SHL high bit");

        // ----------------------
        // SHIFT RIGHT TESTS
        // ----------------------
        // Test: 0x80000000 (2147483648) >> 1 = 0x40000000 (1073741824)
        a = 32'h80000000; op = ALU_SHR;
        #1; check(32'h40000000, 8'b00000000, "SHR by 1");
        // Test: 0x00000003 >> 1 = 0x00000001 (carry set)
        a = 32'h00000003; op = ALU_SHR;
        #1; check(32'h00000001, 8'b00000001, "SHR odd value");

        // ----------------------
        // ARITHMETIC SHIFT RIGHT TESTS
        // ----------------------
        // Test: 0xF0000000 (decimal: -268435456) >>> 4 = 0xFF000000 (decimal: -16777216)
        a = 32'hF0000000; b = 4; op = ALU_SAR;
        #1; check(32'hFF000000, 8'b00000100, "SAR negative");

        // ----------------------
        // MULTIPLICATION TESTS
        // ----------------------
        // Test: 7 * 6 = 42
        a = 32'd7; b = 32'd6; op = ALU_MUL;
        #1; check(32'd42, 8'b00000000, "MUL basic");
        // Test: 12345 * 0 = 0 (zero flag set)
        a = 32'd12345; b = 32'd0; op = ALU_MUL;
        #1; check(32'd0, 8'b00000010, "MUL by zero");

        // ----------------------
        // DIVISION TESTS
        // ----------------------
        // Test: 42 / 6 = 7
        a = 32'd42; b = 32'd6; op = ALU_DIV;
        #1; check(32'd7, 8'b00000000, "DIV basic");
        // Test: 42 / 0 = 0xFFFFFFFF (error, decimal: 4294967295)
        a = 32'd42; b = 32'd0; op = ALU_DIV;
        #1; check(32'hFFFFFFFF, 8'b00000101, "DIV by zero");
        // Test: -10 / 2 = -5
        a = -32'd10; b = 32'd2; op = ALU_DIV;
        #1; check(-32'd5, 8'b00000100, "DIV negative by positive");

        // ----------------------
        // MODULO TESTS
        // ----------------------
        // Test: 43 % 6 = 1
        a = 32'd43; b = 32'd6; op = ALU_MOD;
        #1; check(32'd1, 8'b00000000, "MOD basic");
        // Test: 43 % 0 = 0 (error)
        a = 32'd43; b = 32'd0; op = ALU_MOD;
        #1; check(32'd0, 8'b00000011, "MOD by zero");

        // ----------------------
        // COMPARE TESTS
        // ----------------------
        // Test: 10 == 10 (zero flag set)
        a = 32'd10; b = 32'd10; op = ALU_CMP;
        #1; check(32'd10, 8'b00000000, "CMP equal");
        // Test: 5 < 10 (negative flag set)
        a = 32'd5; b = 32'd10; op = ALU_CMP;
        #1; check(32'd5, 8'b00000001, "CMP less");
        // Test: 15 > 10 (no zero/negative flag)
        a = 32'd15; b = 32'd10; op = ALU_CMP;
        #1; check(32'd15, 8'b00000000, "CMP greater");
        // Test: -1 vs 1 (negative flag set)
        a = -32'd1; b = 32'd1; op = ALU_CMP;
        #1; check(-32'd1, 8'b00000001, "CMP neg vs pos");

        $display("ALU tests complete.");
        $finish;
    end
endmodule
