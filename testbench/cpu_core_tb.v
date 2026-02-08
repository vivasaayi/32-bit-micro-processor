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

    // Instruction encoding helper
    function [31:0] encode_rrr;
        input [5:0] opcode;
        input [4:0] rd, rs1, rs2;
        reg [31:0] instr;
        begin
            instr = {opcode, 2'b00, rd, rs1, rs2, 9'b0};
            $display("[encode_rrr] opcode=0x%02h rd=%0d rs1=%0d rs2=%0d => instr=0x%08h (bin=%032b)", opcode, rd, rs1, rs2, instr, instr);
            encode_rrr = instr;
        end
    endfunction
    function [31:0] encode_ri;
        input [5:0] opcode;
        input [4:0] rd, rs1;
        input [18:0] imm;
        reg [31:0] instr;
        begin
            instr = {opcode, 2'b00, rd, rs1, imm[13:0]};
            $display("[encode_ri] opcode=0x%02h rd=%0d rs1=%0d imm=0x%05h => instr=0x%08h (bin=%032b)", opcode, rd, rs1, imm, instr, instr);
            encode_ri = instr;
        end
    endfunction

    // Test program (instruction memory)
    initial begin
        // Clear memory
        integer i;
        for (i = 0; i < 256; i = i + 1) mem[i] = 32'h0;

        // Place instructions at the correct memory base (PC=0x8000)
        // Load test values into R1 and R2
        mem[MEM_BASE + 0] = encode_ri(6'h12, 5'd1, 5'd0, 19'd5);   // LOADI R1, 5
        mem[MEM_BASE + 1] = encode_ri(6'h12, 5'd2, 5'd0, 19'd3);   // LOADI R2, 3
        // ALU ops: R3 = R1 op R2
        mem[MEM_BASE + 2] = encode_rrr(6'h00, 5'd3, 5'd1, 5'd2);   // ADD R3, R1, R2
        mem[MEM_BASE + 3] = encode_rrr(6'h01, 5'd4, 5'd1, 5'd2);   // SUB R4, R1, R2
        mem[MEM_BASE + 4] = encode_rrr(6'h02, 5'd5, 5'd1, 5'd2);   // AND R5, R1, R2
        mem[MEM_BASE + 5] = encode_rrr(6'h03, 5'd6, 5'd1, 5'd2);   // OR  R6, R1, R2
        mem[MEM_BASE + 6] = encode_rrr(6'h04, 5'd7, 5'd1, 5'd2);   // XOR R7, R1, R2
        mem[MEM_BASE + 7] = encode_rrr(6'h05, 5'd8, 5'd1, 5'd0);   // NOT R8, R1
        mem[MEM_BASE + 8] = encode_rrr(6'h06, 5'd9, 5'd1, 5'd2);   // SHL R9, R1, R2
        mem[MEM_BASE + 9] = encode_rrr(6'h07, 5'd10, 5'd1, 5'd2);  // SHR R10, R1, R2
        mem[MEM_BASE + 10] = encode_rrr(6'h0C, 5'd11, 5'd1, 5'd2); // SAR R11, R1, R2
        mem[MEM_BASE + 11] = encode_rrr(6'h08, 5'd12, 5'd1, 5'd2); // MUL R12, R1, R2
        mem[MEM_BASE + 12] = encode_rrr(6'h09, 5'd13, 5'd1, 5'd2); // DIV R13, R1, R2
        mem[MEM_BASE + 13] = encode_rrr(6'h0A, 5'd14, 5'd1, 5'd2); // MOD R14, R1, R2
        mem[MEM_BASE + 14] = encode_rrr(6'h0B, 5'd15, 5'd1, 5'd2); // CMP R15, R1, R2
        mem[MEM_BASE + 15] = encode_rrr(6'h3E, 5'd0, 5'd0, 5'd0);  // HALT (updated opcode to 0x3E)

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
