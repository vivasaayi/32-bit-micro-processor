// alu_tb.v - Comprehensive testbench for RISC-V 32-bit ALU
//
// Tests all RV32I and RV32M ALU operations.
// RISC-V has no architectural flags; we verify result only.

`timescale 1ns/1ps

module alu_tb;
    reg  [31:0] a, b;
    reg  [6:0]  opcode;
    reg  [2:0]  funct3;
    reg  [6:0]  funct7;
    wire [31:0] result;

    integer pass_count, fail_count;

    // Instantiate the ALU
    alu uut (
        .a(a),
        .b(b),
        .opcode(opcode),
        .funct3(funct3),
        .funct7(funct7),
        .result(result)
    );

    // RISC-V Opcodes
    localparam OP_REG   = 7'h33;
    localparam OP_IMM   = 7'h13;
    localparam OP_LUI   = 7'h37;
    localparam OP_AUIPC = 7'h17;
    localparam OP_LOAD  = 7'h03;
    localparam OP_STORE = 7'h23;
    localparam OP_JALR  = 7'h67;

    // Helper task - check result only (RISC-V has no flags)
    task check;
        input [31:0] exp_result;
        input [255:0] msg;
        begin
            #1;
            if (result !== exp_result) begin
                $display("FAIL: %0s | a=0x%08h b=0x%08h op=%02h f3=%01h f7=%02h => 0x%08h (exp 0x%08h)",
                    msg, a, b, opcode, funct3, funct7, result, exp_result);
                fail_count = fail_count + 1;
            end else begin
                $display("PASS: %0s | a=0x%08h b=0x%08h => 0x%08h",
                    msg, a, b, result);
                pass_count = pass_count + 1;
            end
        end
    endtask

    initial begin
        $display("========================================");
        $display("  RISC-V ALU Testbench");
        $display("========================================");
        pass_count = 0;
        fail_count = 0;

        // ==============================================
        // R-TYPE (opcode = 0x33)
        // ==============================================

        // --- ADD (funct3=0x0, funct7=0x00) ---
        a = 32'd10;        b = 32'd5;         opcode = OP_REG; funct3 = 3'h0; funct7 = 7'h00;
        #1; check(32'd15,           "ADD 10+5");
        a = 32'd0;         b = 32'd0;         opcode = OP_REG; funct3 = 3'h0; funct7 = 7'h00;
        #1; check(32'd0,            "ADD 0+0");
        a = 32'hFFFFFFFF;  b = 32'd1;         opcode = OP_REG; funct3 = 3'h0; funct7 = 7'h00;
        #1; check(32'd0,            "ADD overflow wrap");
        a = 32'h7FFFFFFF;  b = 32'd1;         opcode = OP_REG; funct3 = 3'h0; funct7 = 7'h00;
        #1; check(32'h80000000,     "ADD signed overflow");

        // --- SUB (funct3=0x0, funct7=0x20) ---
        a = 32'd10;        b = 32'd4;         opcode = OP_REG; funct3 = 3'h0; funct7 = 7'h20;
        #1; check(32'd6,            "SUB 10-4");
        a = 32'd0;         b = 32'd1;         opcode = OP_REG; funct3 = 3'h0; funct7 = 7'h20;
        #1; check(32'hFFFFFFFF,     "SUB 0-1 wrap");
        a = 32'd0;         b = 32'd0;         opcode = OP_REG; funct3 = 3'h0; funct7 = 7'h20;
        #1; check(32'd0,            "SUB 0-0");

        // --- SLL (funct3=0x1, funct7=0x00) ---
        a = 32'h00000001;  b = 32'd1;         opcode = OP_REG; funct3 = 3'h1; funct7 = 7'h00;
        #1; check(32'h00000002,     "SLL 1<<1");
        a = 32'h00000001;  b = 32'd31;        opcode = OP_REG; funct3 = 3'h1; funct7 = 7'h00;
        #1; check(32'h80000000,     "SLL 1<<31");
        a = 32'h80000000;  b = 32'd1;         opcode = OP_REG; funct3 = 3'h1; funct7 = 7'h00;
        #1; check(32'h00000000,     "SLL shift out");

        // --- SLT (funct3=0x2, funct7=0x00) ---
        a = 32'd5;         b = 32'd10;        opcode = OP_REG; funct3 = 3'h2; funct7 = 7'h00;
        #1; check(32'd1,            "SLT 5<10 signed");
        a = 32'd10;        b = 32'd5;         opcode = OP_REG; funct3 = 3'h2; funct7 = 7'h00;
        #1; check(32'd0,            "SLT 10<5 signed");
        a = 32'hFFFFFFFF;  b = 32'd0;         opcode = OP_REG; funct3 = 3'h2; funct7 = 7'h00;
        #1; check(32'd1,            "SLT -1<0 signed");

        // --- SLTU (funct3=0x3, funct7=0x00) ---
        a = 32'd5;         b = 32'd10;        opcode = OP_REG; funct3 = 3'h3; funct7 = 7'h00;
        #1; check(32'd1,            "SLTU 5<10");
        a = 32'hFFFFFFFF;  b = 32'd0;         opcode = OP_REG; funct3 = 3'h3; funct7 = 7'h00;
        #1; check(32'd0,            "SLTU max<0 unsigned");
        a = 32'd0;         b = 32'hFFFFFFFF;  opcode = OP_REG; funct3 = 3'h3; funct7 = 7'h00;
        #1; check(32'd1,            "SLTU 0<max unsigned");

        // --- XOR (funct3=0x4, funct7=0x00) ---
        a = 32'hFF00FF00;  b = 32'h00FF00FF;  opcode = OP_REG; funct3 = 3'h4; funct7 = 7'h00;
        #1; check(32'hFFFFFFFF,     "XOR complement");
        a = 32'hAAAAAAAA;  b = 32'hAAAAAAAA;  opcode = OP_REG; funct3 = 3'h4; funct7 = 7'h00;
        #1; check(32'h00000000,     "XOR same=0");

        // --- SRL (funct3=0x5, funct7=0x00) ---
        a = 32'h80000000;  b = 32'd1;         opcode = OP_REG; funct3 = 3'h5; funct7 = 7'h00;
        #1; check(32'h40000000,     "SRL logical");
        a = 32'hFFFFFFFF;  b = 32'd4;         opcode = OP_REG; funct3 = 3'h5; funct7 = 7'h00;
        #1; check(32'h0FFFFFFF,     "SRL -1>>4");

        // --- SRA (funct3=0x5, funct7=0x20) ---
        a = 32'h80000000;  b = 32'd1;         opcode = OP_REG; funct3 = 3'h5; funct7 = 7'h20;
        #1; check(32'hC0000000,     "SRA sign-extend");
        a = 32'hF0000000;  b = 32'd4;         opcode = OP_REG; funct3 = 3'h5; funct7 = 7'h20;
        #1; check(32'hFF000000,     "SRA negative>>4");
        a = 32'h40000000;  b = 32'd1;         opcode = OP_REG; funct3 = 3'h5; funct7 = 7'h20;
        #1; check(32'h20000000,     "SRA positive>>1");

        // --- OR (funct3=0x6, funct7=0x00) ---
        a = 32'hF0F0F0F0;  b = 32'h0F0F0F0F; opcode = OP_REG; funct3 = 3'h6; funct7 = 7'h00;
        #1; check(32'hFFFFFFFF,     "OR complement");
        a = 32'h00000000;  b = 32'hABCDEF01; opcode = OP_REG; funct3 = 3'h6; funct7 = 7'h00;
        #1; check(32'hABCDEF01,     "OR with zero");

        // --- AND (funct3=0x7, funct7=0x00) ---
        a = 32'hF0F0F0F0;  b = 32'h0F0F0F0F; opcode = OP_REG; funct3 = 3'h7; funct7 = 7'h00;
        #1; check(32'h00000000,     "AND disjoint");
        a = 32'hFFFFFFFF;  b = 32'h12345678; opcode = OP_REG; funct3 = 3'h7; funct7 = 7'h00;
        #1; check(32'h12345678,     "AND with all-1s");

        // ==============================================
        // I-TYPE (opcode = 0x13)
        // ==============================================

        // --- ADDI (funct3=0x0) ---
        a = 32'd10;        b = 32'd5;         opcode = OP_IMM; funct3 = 3'h0; funct7 = 7'h00;
        #1; check(32'd15,           "ADDI 10+5");
        a = 32'd100;       b = -32'd1;        opcode = OP_IMM; funct3 = 3'h0; funct7 = 7'h00;
        #1; check(32'd99,           "ADDI 100+(-1)");

        // --- SLTI (funct3=0x2) ---
        a = 32'd5;         b = 32'd10;        opcode = OP_IMM; funct3 = 3'h2; funct7 = 7'h00;
        #1; check(32'd1,            "SLTI 5<10");
        a = 32'd10;        b = 32'd5;         opcode = OP_IMM; funct3 = 3'h2; funct7 = 7'h00;
        #1; check(32'd0,            "SLTI 10<5");

        // --- SLTIU (funct3=0x3) ---
        a = 32'd5;         b = 32'd10;        opcode = OP_IMM; funct3 = 3'h3; funct7 = 7'h00;
        #1; check(32'd1,            "SLTIU 5<10");
        a = 32'hFFFFFFFF;  b = 32'd1;         opcode = OP_IMM; funct3 = 3'h3; funct7 = 7'h00;
        #1; check(32'd0,            "SLTIU max<1");

        // --- XORI (funct3=0x4) ---
        a = 32'hFF00FF00;  b = 32'h0F0F0F0F;  opcode = OP_IMM; funct3 = 3'h4; funct7 = 7'h00;
        #1; check(32'hF00FF00F,     "XORI");

        // --- ORI (funct3=0x6) ---
        a = 32'hFF000000;  b = 32'h000000FF;  opcode = OP_IMM; funct3 = 3'h6; funct7 = 7'h00;
        #1; check(32'hFF0000FF,     "ORI");

        // --- ANDI (funct3=0x7) ---
        a = 32'hFF00FF00;  b = 32'h0F0F0F0F;  opcode = OP_IMM; funct3 = 3'h7; funct7 = 7'h00;
        #1; check(32'h0F000F00,     "ANDI");

        // --- SLLI (funct3=0x1) ---
        a = 32'd1;         b = 32'd4;         opcode = OP_IMM; funct3 = 3'h1; funct7 = 7'h00;
        #1; check(32'd16,           "SLLI 1<<4");

        // --- SRLI (funct3=0x5, funct7=0x00) ---
        a = 32'd16;        b = 32'd2;         opcode = OP_IMM; funct3 = 3'h5; funct7 = 7'h00;
        #1; check(32'd4,            "SRLI 16>>2");

        // --- SRAI (funct3=0x5, funct7=0x20) ---
        a = -32'd4;        b = 32'd1;         opcode = OP_IMM; funct3 = 3'h5; funct7 = 7'h20;
        #1; check(-32'd2,           "SRAI -4>>1");

        // ==============================================
        // U-TYPE / J-TYPE helpers
        // ==============================================

        // --- LUI (opcode=0x37) ---
        a = 32'd0;         b = 32'hDEAD0000;  opcode = OP_LUI; funct3 = 3'h0; funct7 = 7'h00;
        #1; check(32'hDEAD0000,     "LUI passthrough");

        // --- AUIPC (opcode=0x17) ---
        a = 32'h00001000;  b = 32'h12345000;  opcode = OP_AUIPC; funct3 = 3'h0; funct7 = 7'h00;
        #1; check(32'h12346000,     "AUIPC PC+imm");

        // ==============================================
        // Address calculation (LOAD/STORE/JALR)
        // ==============================================
        a = 32'h10000000;  b = 32'd16;        opcode = OP_LOAD; funct3 = 3'h0; funct7 = 7'h00;
        #1; check(32'h10000010,     "LOAD addr calc");
        a = 32'h20000000;  b = 32'd32;        opcode = OP_STORE; funct3 = 3'h0; funct7 = 7'h00;
        #1; check(32'h20000020,     "STORE addr calc");
        a = 32'h30000000;  b = 32'd8;         opcode = OP_JALR; funct3 = 3'h0; funct7 = 7'h00;
        #1; check(32'h30000008,     "JALR addr calc");

        // ==============================================
        // RV32M extension (opcode=0x33, funct7=0x01)
        // ==============================================

        // --- MUL (funct3=0x0) ---
        a = 32'd7;         b = 32'd6;         opcode = OP_REG; funct3 = 3'h0; funct7 = 7'h01;
        #1; check(32'd42,           "MUL 7*6");
        a = 32'd0;         b = 32'd999;       opcode = OP_REG; funct3 = 3'h0; funct7 = 7'h01;
        #1; check(32'd0,            "MUL by zero");

        // --- MULH (funct3=0x1) ---
        a = 32'h00008000;  b = 32'h00008000;  opcode = OP_REG; funct3 = 3'h1; funct7 = 7'h01;
        #1; check(32'h00000000,     "MULH 0x8000*0x8000");
        a = -32'd1000;     b = 32'd1000;      opcode = OP_REG; funct3 = 3'h1; funct7 = 7'h01;
        #1; check(32'hFFFFFFFF,     "MULH (-1000)*1000");

        // --- MULHSU (funct3=0x2) ---
        a = -32'd1;        b = 32'h80000000;  opcode = OP_REG; funct3 = 3'h2; funct7 = 7'h01;
        #1; check(32'hFFFFFFFF,     "MULHSU (-1)*0x80000000");
        a = 32'h40000000;  b = 32'h40000000;  opcode = OP_REG; funct3 = 3'h2; funct7 = 7'h01;
        #1; check(32'h10000000,     "MULHSU 0x40000000*0x40000000");

        // --- MULHU (funct3=0x3) ---
        a = 32'h80000000;  b = 32'h80000000;  opcode = OP_REG; funct3 = 3'h3; funct7 = 7'h01;
        #1; check(32'h40000000,     "MULHU 0x80000000*0x80000000");
        a = 32'hFFFFFFFF;  b = 32'hFFFFFFFF;  opcode = OP_REG; funct3 = 3'h3; funct7 = 7'h01;
        #1; check(32'hFFFFFFFE,     "MULHU max*max");

        // --- DIV (funct3=0x4) ---
        a = 32'd42;        b = 32'd6;         opcode = OP_REG; funct3 = 3'h4; funct7 = 7'h01;
        #1; check(32'd7,            "DIV 42/6");
        a = 32'd42;        b = 32'd0;         opcode = OP_REG; funct3 = 3'h4; funct7 = 7'h01;
        #1; check(32'hFFFFFFFF,     "DIV by zero");
        a = 32'h80000000;  b = 32'hFFFFFFFF;  opcode = OP_REG; funct3 = 3'h4; funct7 = 7'h01;
        #1; check(32'h80000000,     "DIV INT_MIN/-1");

        // --- DIVU (funct3=0x5) ---
        a = 32'hFFFFFFFF;  b = 32'd2;         opcode = OP_REG; funct3 = 3'h5; funct7 = 7'h01;
        #1; check(32'h7FFFFFFF,     "DIVU max/2");

        // --- REM (funct3=0x6) ---
        a = 32'd43;        b = 32'd6;         opcode = OP_REG; funct3 = 3'h6; funct7 = 7'h01;
        #1; check(32'd1,            "REM 43%6");
        a = 32'd43;        b = 32'd0;         opcode = OP_REG; funct3 = 3'h6; funct7 = 7'h01;
        #1; check(32'd43,           "REM div by zero");
        a = 32'h80000000;  b = 32'hFFFFFFFF;  opcode = OP_REG; funct3 = 3'h6; funct7 = 7'h01;
        #1; check(32'd0,            "REM INT_MIN%-1");

        // --- REMU (funct3=0x7) ---
        a = 32'hFFFFFFFF;  b = 32'd10;        opcode = OP_REG; funct3 = 3'h7; funct7 = 7'h01;
        #1; check(32'd5,            "REMU max%10");

        // ==============================================
        // Unknown opcode -> 0
        // ==============================================
        a = 32'hDEADBEEF;  b = 32'h12345678;  opcode = 7'h7F; funct3 = 3'h0; funct7 = 7'h00;
        #1; check(32'h0,            "Unknown opcode");

        // ==============================================
        // SUMMARY
        // ==============================================
        $display("========================================");
        $display("  Results: %0d PASSED, %0d FAILED", pass_count, fail_count);
        $display("========================================");
        if (fail_count == 0)
            $display("ALL TESTS PASSED");
        else
            $display("SOME TESTS FAILED");
        $finish;
    end
endmodule
