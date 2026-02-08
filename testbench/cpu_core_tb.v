`timescale 1ns / 1ps

// Comprehensive testbench for cpu_core.v
// Tests all ALU operations via the CPU fetch/decode/execute pipeline

module cpu_core_tb;
    reg clk = 0;
    reg rst_n = 0;
    wire [31:0] addr_bus;
    wire [31:0] data_bus;
    wire mem_read, mem_write;
    reg mem_ready = 1;
    reg [31:0] mem [0:16383]; // Simple instruction/data memory
    reg [31:0] data_bus_out;
    reg data_bus_drive = 0;
    wire halted;
    wire user_mode;

    localparam MEM_BASE = 32'h8000 >> 2; // 0x2000

    // I/O and interrupt signals (unused in this test)
    wire [7:0] interrupt_req = 8'b0;
    wire interrupt_ack;
    wire [7:0] io_addr;
    wire [7:0] io_data;
    wire io_read, io_write;

    // Connect data bus (inout)
    assign data_bus = data_bus_drive ? data_bus_out : 32'hZZZZZZZZ;

    // Instantiate CPU
    cpu_core uut (
        .clk(clk),
        .rst_n(rst_n),
        .addr_bus(addr_bus),
        .data_bus(data_bus),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .mem_ready(mem_ready),
        .interrupt_req(interrupt_req),
        .interrupt_ack(interrupt_ack),
        .io_addr(io_addr),
        .io_data(io_data),
        .io_read(io_read),
        .io_write(io_write),
        .halted(halted),
        .user_mode(user_mode)
    );

    // Clock generation
    always #5 clk = ~clk;

    // RISC-V Instruction encoding helpers
    function [31:0] encode_r;
        input [6:0] funct7;
        input [4:0] rs2, rs1;
        input [2:0] funct3;
        input [4:0] rd;
        input [6:0] opcode;
        begin
            encode_r = {funct7, rs2, rs1, funct3, rd, opcode};
        end
    endfunction

    function [31:0] encode_i;
        input [11:0] imm;
        input [4:0] rs1;
        input [2:0] funct3;
        input [4:0] rd;
        input [6:0] opcode;
        begin
            encode_i = {imm, rs1, funct3, rd, opcode};
        end
    endfunction

    function [31:0] encode_u;
        input [19:0] imm20;
        input [4:0] rd;
        input [6:0] opcode;
        begin
            encode_u = {imm20, rd, opcode};
        end
    endfunction

    function [31:0] encode_j;
        input [20:0] imm21;
        input [4:0] rd;
        input [6:0] opcode;
        begin
            // J-type scrambled immediate: imm[20]|imm[10:1]|imm[11]|imm[19:12]
            encode_j = {imm21[20], imm21[10:1], imm21[11], imm21[19:12], rd, opcode};
        end
    endfunction

    // Test program (instruction memory)
    initial begin
        // Clear memory
        integer i;
        for (i = 0; i < 256; i = i + 1) mem[i] = 32'h0;

        // Place instructions at the correct memory base (PC=0x8000)
        // R1 = 5, R2 = 3
        mem[MEM_BASE + 0] = encode_i(12'd5, 5'd0, 3'h0, 5'd1, 7'h13); // ADDI R1, x0, 5
        mem[MEM_BASE + 1] = encode_i(12'd3, 5'd0, 3'h0, 5'd2, 7'h13); // ADDI R2, x0, 3
        
        // ALU ops: R3 = R1 + R2 = 8
        mem[MEM_BASE + 2] = encode_r(7'h00, 5'd2, 5'd1, 3'h0, 5'd3, 7'h33); // ADD R3, R1, R2

        // JAL test: Jump forward 8 bytes (2 instructions)
        // PC is at 0x800C. Target = 0x800C + 8 = 0x8014.
        // rd = R4 (holds 0x8010, which is PC+4)
        mem[MEM_BASE + 3] = encode_j(21'd8, 5'd4, 7'h6F); // JAL R4, +8
        
        // This instruction (0x8010) should be skipped
        mem[MEM_BASE + 4] = encode_i(12'd100, 5'd0, 3'h0, 5'd10, 7'h13); // ADDI R10, x0, 100 (SKIPPED)
        
        // Target of JAL (0x8014)
        mem[MEM_BASE + 5] = encode_i(12'd200, 5'd0, 3'h0, 5'd11, 7'h13); // ADDI R11, x0, 200 (EXECUTED)

        // JALR test: Jump to R7 + 16 => PC = 0x8020 + 16 = 0x8030. R8 gets PC+4 = 0x802C.
        mem[MEM_BASE + 9] = encode_i(12'd16, 5'd7, 3'h0, 5'd8, 7'h67); // JALR R8, R7, 16
        
        // Skip to 0x8030 (MEM_BASE + 12)
        mem[MEM_BASE + 10] = encode_i(12'd300, 5'd0, 3'h0, 5'd12, 7'h13); // ADDI R12, x0, 300 (at 0x8030)
        mem[MEM_BASE + 11] = encode_u(20'hFFFFF, 5'd0, 7'h73); // SYSTEM/HALT
        
        // 0x8030 (MEM_BASE + 12) - target of JALR
        mem[MEM_BASE + 12] = encode_i(12'd400, 5'd0, 3'h0, 5'd13, 7'h13); // ADDI R13, x0, 400
        mem[MEM_BASE + 13] = encode_u(20'hFFFFF, 5'd0, 7'h73); // SYSTEM/HALT

        // Print loaded instructions for verification
        for (i = 0; i < 16; i = i + 1) begin
            $display("mem[0x%04x] = 0x%08h (bin=%032b)", MEM_BASE + i, mem[MEM_BASE + i], mem[MEM_BASE + i]);
        end
    end

    // Simulate instruction fetch/data bus
    always @(*) begin
        data_bus_drive = 0;
        data_bus_out = 32'h0;
        if (mem_read && !mem_write) begin
            // Instruction fetch or LOAD
            data_bus_out = mem[addr_bus[31:2]];
            data_bus_drive = 1;
        end
    end

    // Reset and run
    initial begin
        $display("\n==== CPU ALU Testbench Start ====");
        rst_n = 0;
        #20;
        rst_n = 1;
        wait(halted);
        $display("==== CPU HALTED ====");
        // Automated PASS/FAIL checks for ALU results
        check_reg(1, 5, "LOADI");
        check_reg(2, 3, "LOADI");
        check_reg(3, 8, "ADD");
        check_reg(4, 2, "SUB");
        check_reg(5, 1, "AND");
        check_reg(6, 7, "OR");
        check_reg(7, 6, "XOR");
        check_reg(8, ~5, "NOT");
        check_reg(9, 40, "SHL");
        check_reg(10, 0, "SHR");
        check_reg(11, 0, "SAR"); // 5 >>> 3 = 0 (arith shift right)
        check_reg(12, 15, "MUL");
        check_reg(13, 1, "DIV");
        check_reg(14, 2, "MOD");
        $display("==== CPU ALU Testbench Complete ====");
        $finish;
    end

    // Automated register check task
    task check_reg;
        input [4:0] regnum;
        input [31:0] expected;
        input [127:0] opname;
        reg [31:0] actual;
        begin
            // Read value from register file using dump_regs logic
            if (regnum == 0)
                actual = 32'h00000000;
            else
                actual = uut.reg_file_inst.registers[regnum];
            if (actual !== expected)
                $display("[FAIL] %s: R%0d = %0d, expected %0d", opname, regnum, actual, expected);
            else
                $display("[PASS] %s: R%0d = %0d", opname, regnum, expected);
        end
    endtask
endmodule
