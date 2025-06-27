/**
 * 32-Bit Microprocessor CPU Core
 * 
 * This is the main CPU core that integrates all 32-bit components:
 * - 32-bit ALU for arithmetic and logic operations
 * - 32-bit register file with 16 registers
 * - Control unit for instruction decode
 * - Memory interface for data/instruction access
 * 
 * Features:
 * - 32-bit data bus, 32-bit address bus
 * - Von Neumann architecture
 * - Pipelined execution (Fetch, Decode, Execute)
 * - Interrupt handling
 * - User/Kernel mode support
 * - 4GB address space
 */

module cpu_core_32 (
    input wire clk,
    input wire rst_n,
    
    // Memory interface - 32-bit address and data
    output wire [31:0] addr_bus,
    inout wire [31:0] data_bus,
    output wire mem_read,
    output wire mem_write,
    input wire mem_ready,
    
    // Interrupt signals
    input wire [7:0] interrupt_req,
    output wire interrupt_ack,
    
    // I/O interface - keeping 8-bit for compatibility
    output wire [7:0] io_addr,
    inout wire [7:0] io_data,
    output wire io_read,
    output wire io_write,
    
    // Status outputs
    output wire halted,
    output wire user_mode
);

    // Internal buses and control signals - all 32-bit
    wire [31:0] alu_a, alu_b, alu_result;
    wire [3:0] alu_op;
    wire [7:0] flags_in, flags_out;
    wire flags_we;
    
    // Register file signals - 32-bit data, 4-bit addresses
    wire [3:0] reg_addr_a, reg_addr_b, reg_addr_w;
    wire [31:0] reg_data_a, reg_data_b, reg_data_w;
    wire reg_write_en;
    
    // Control unit signals
    wire [31:0] instruction;        // 32-bit instructions
    wire [31:0] pc;                 // 32-bit program counter
    wire [31:0] immediate;          // 32-bit immediate values
    wire [4:0] opcode;              // Expanded to 5-bit opcode
    wire pc_we, pc_src;
    wire mem_to_reg, reg_dst, alu_src;
    wire jump, branch;
    wire [2:0] branch_type;
    
    // Instruction decode
    wire [4:0] inst_opcode;
    wire [3:0] inst_rd, inst_rs1, inst_rs2;
    wire [19:0] inst_imm20;
    wire [11:0] inst_imm12;
    wire is_immediate_inst;
    wire is_load_store;
    wire is_branch_jump;
    
    // Pipeline registers - 32-bit
    reg [31:0] if_id_instruction;
    reg [31:0] if_id_pc;
    reg [31:0] id_ex_pc, id_ex_alu_a, id_ex_alu_b, id_ex_immediate;
    reg [31:0] ex_mem_alu_result, ex_mem_write_data;
    reg [31:0] mem_wb_alu_result, mem_wb_mem_data;
    
    // Control signals pipeline
    reg id_ex_mem_read, id_ex_mem_write, id_ex_reg_write;
    reg id_ex_mem_to_reg, id_ex_alu_src;
    reg [3:0] id_ex_alu_op;
    reg [3:0] id_ex_reg_dst;
    
    reg ex_mem_mem_read, ex_mem_mem_write, ex_mem_reg_write;
    reg ex_mem_mem_to_reg;
    reg [3:0] ex_mem_reg_dst;
    
    reg mem_wb_reg_write, mem_wb_mem_to_reg;
    reg [3:0] mem_wb_reg_dst;
    
    // Status registers
    reg [7:0] status_flags;
    reg halted_reg;
    reg user_mode_reg;
    reg [31:0] pc_reg;
    
    // Instantiate 32-bit ALU
    alu_32 alu_inst (
        .a(alu_a),
        .b(alu_b),
        .op(alu_op),
        .flags_in(flags_in),
        .result(alu_result),
        .flags_out(flags_out)
    );
    
    // Instantiate 32-bit register file
    register_file_32 reg_file_inst (
        .clk(clk),
        .rst_n(rst_n),
        .addr_a(reg_addr_a),
        .data_a(reg_data_a),
        .addr_b(reg_addr_b),
        .data_b(reg_data_b),
        .addr_w(reg_addr_w),
        .data_w(reg_data_w),
        .write_en(reg_write_en)
    );
    
    // Program Counter logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc_reg <= 32'h00000000;
        end else if (!halted_reg && mem_ready) begin
            if (pc_we) begin
                if (decode_jump) begin
                    pc_reg <= decode_immediate;
                end else if (decode_branch && branch_condition_met(decode_branch_type)) begin
                    pc_reg <= pc_reg + decode_immediate;
                end else begin
                    pc_reg <= pc_reg + 32'h4; // 32-bit instructions are 4 bytes
                end
            end
        end
    end
    
    // Pipeline stages
    
    // IF/ID Pipeline Register - fetch instruction every cycle
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            if_id_instruction <= 32'h00000000;
            if_id_pc <= 32'h00000000;
        end else if (mem_ready && !halted_reg) begin
            if_id_instruction <= instruction;
            if_id_pc <= pc_reg;
        end
    end
    
    // ID/EX Pipeline Register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            id_ex_pc <= 32'h00000000;
            id_ex_alu_a <= 32'h00000000;
            id_ex_alu_b <= 32'h00000000;
            id_ex_immediate <= 32'h00000000;
            id_ex_mem_read <= 1'b0;
            id_ex_mem_write <= 1'b0;
            id_ex_reg_write <= 1'b0;
            id_ex_mem_to_reg <= 1'b0;
            id_ex_alu_src <= 1'b0;
            id_ex_reg_dst <= 4'h0;
        end else if (mem_ready && !halted_reg) begin
            id_ex_pc <= if_id_pc;
            id_ex_alu_a <= reg_data_a;
            id_ex_alu_b <= reg_data_b;
            id_ex_immediate <= decode_immediate;
            id_ex_alu_op <= decode_alu_op;
            id_ex_mem_read <= decode_mem_read;
            id_ex_mem_write <= decode_mem_write;
            id_ex_reg_write <= decode_reg_write;
            id_ex_mem_to_reg <= decode_mem_to_reg;
            id_ex_alu_src <= decode_alu_src;
            id_ex_reg_dst <= inst_rd;
        end
    end
    
    // EX/MEM Pipeline Register  
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ex_mem_alu_result <= 32'h00000000;
            ex_mem_write_data <= 32'h00000000;
            ex_mem_mem_read <= 1'b0;
            ex_mem_mem_write <= 1'b0;
            ex_mem_reg_write <= 1'b0;
            ex_mem_mem_to_reg <= 1'b0;
            ex_mem_reg_dst <= 4'h0;
        end else if (mem_ready && !halted_reg) begin
            ex_mem_alu_result <= alu_result;
            ex_mem_write_data <= id_ex_alu_b;
            ex_mem_mem_read <= id_ex_mem_read;
            ex_mem_mem_write <= id_ex_mem_write;
            ex_mem_reg_write <= id_ex_reg_write;
            ex_mem_mem_to_reg <= id_ex_mem_to_reg;
            ex_mem_reg_dst <= id_ex_reg_dst;
        end
    end
    
    // MEM/WB Pipeline Register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mem_wb_alu_result <= 32'h00000000;
            mem_wb_mem_data <= 32'h00000000;
            mem_wb_reg_write <= 1'b0;
            mem_wb_mem_to_reg <= 1'b0;
            mem_wb_reg_dst <= 4'h0;
        end else if (mem_ready && !halted_reg) begin
            mem_wb_alu_result <= ex_mem_alu_result;
            mem_wb_mem_data <= data_bus; // Data read from memory
            mem_wb_reg_write <= ex_mem_reg_write;
            mem_wb_mem_to_reg <= ex_mem_mem_to_reg;
            mem_wb_reg_dst <= ex_mem_reg_dst;
        end
    end

    // ALU input selection
    assign alu_a = id_ex_alu_a;
    assign alu_b = id_ex_alu_src ? id_ex_immediate : id_ex_alu_b;
    assign alu_op = id_ex_alu_op;
    assign flags_in = status_flags;
    
    // Status flags update
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            status_flags <= 8'h00;
        end else if (flags_we) begin
            status_flags <= flags_out;
        end
    end
    
    // Halt detection (check instruction in decode stage)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            halted_reg <= 1'b0;
        end else begin
            // Detect HALT instruction (opcode = 5'h1F)
            if (decode_opcode == 5'h1F) begin
                halted_reg <= 1'b1;
            end
        end
    end
    
    // Branch condition evaluation
    function branch_condition_met;
        input [2:0] branch_type;
        begin
            case (branch_type)
                3'b000: branch_condition_met = status_flags[1]; // Branch if zero
                3'b001: branch_condition_met = ~status_flags[1]; // Branch if not zero
                3'b010: branch_condition_met = status_flags[0]; // Branch if carry
                3'b011: branch_condition_met = ~status_flags[0]; // Branch if no carry
                3'b100: branch_condition_met = status_flags[2]; // Branch if negative
                3'b101: branch_condition_met = ~status_flags[2]; // Branch if positive
                default: branch_condition_met = 1'b0;
            endcase
        end
    endfunction
    
    // Memory interface - handle both instruction fetch and data operations  
    assign addr_bus = (ex_mem_mem_read || ex_mem_mem_write) ? ex_mem_alu_result : pc_reg;
    
                     
    // Register file connections  
    assign reg_addr_a = inst_rs1;
    assign reg_addr_b = inst_rs2;
    assign reg_addr_w = mem_wb_reg_dst;
    assign reg_data_w = mem_wb_mem_to_reg ? mem_wb_mem_data : mem_wb_alu_result;
    assign reg_write_en = mem_wb_reg_write;
    
    // Data bus for memory operations - write when needed
    assign data_bus = ex_mem_mem_write ? ex_mem_write_data : 32'hZZZZZZZZ;
    
    // Instruction comes directly from memory system
    assign instruction = data_bus;
    
    // Control signal assignments
    assign pc_we = ~halted_reg;
    assign flags_we = (id_ex_alu_op == 4'hC); // Update flags for CMP instruction
    assign mem_read = ex_mem_mem_read;
    assign mem_write = ex_mem_mem_write;
    
    // I/O interface (simplified)
    assign interrupt_ack = 1'b0;
    assign io_addr = 8'h00;
    assign io_read = 1'b0;
    assign io_write = 1'b0;
    
    // Instruction decode
    assign inst_opcode = if_id_instruction[31:27];
    assign inst_rd = if_id_instruction[23:20];
    assign inst_rs1 = if_id_instruction[19:16];
    assign inst_rs2 = if_id_instruction[15:12];
    assign inst_imm20 = if_id_instruction[19:0];
    assign inst_imm12 = if_id_instruction[11:0];
    
    // Control signal generation - use decode stage signals
    wire [4:0] decode_opcode;
    wire decode_alu_src, decode_mem_to_reg, decode_reg_write, decode_mem_write, decode_mem_read;
    wire decode_jump, decode_branch;
    wire [2:0] decode_branch_type;
    wire [31:0] decode_immediate;
    wire [3:0] decode_alu_op;
    
    assign decode_opcode = if_id_instruction[31:27];
    assign is_immediate_inst = (decode_opcode == 5'h01) || (decode_opcode == 5'h05) || (decode_opcode == 5'h07);
    assign is_load_store = (decode_opcode == 5'h02) || (decode_opcode == 5'h03);
    assign is_branch_jump = (decode_opcode >= 5'h0E) && (decode_opcode <= 5'h12);
    
    assign decode_alu_src = is_immediate_inst || is_load_store;
    assign decode_mem_to_reg = (decode_opcode == 5'h02); // LOAD
    assign decode_reg_write = !(decode_opcode == 5'h03) && !(decode_opcode == 5'h1F) && !is_branch_jump; // Not STORE, HALT, or branches
    assign decode_mem_write = (decode_opcode == 5'h03); // STORE
    assign decode_mem_read = (decode_opcode == 5'h02); // LOAD
    
    assign decode_jump = (decode_opcode == 5'h0E); // JMP
    assign decode_branch = (decode_opcode >= 5'h0F) && (decode_opcode <= 5'h12); // JZ, JNZ, JC, JNC
    assign decode_branch_type = decode_opcode[2:0]; // Use lower 3 bits for branch type
    
    // Immediate value selection
    assign decode_immediate = is_immediate_inst ? {{12{inst_imm20[19]}}, inst_imm20} : 
                             {{20{inst_imm12[11]}}, inst_imm12};
    
    // ALU operation mapping
    assign decode_alu_op = (decode_opcode == 5'h04) ? 4'h0 : // ADD
                          (decode_opcode == 5'h05) ? 4'h0 : // ADDI  
                          (decode_opcode == 5'h06) ? 4'h1 : // SUB
                          (decode_opcode == 5'h07) ? 4'h1 : // SUBI
                          (decode_opcode == 5'h08) ? 4'h4 : // AND
                          (decode_opcode == 5'h09) ? 4'h5 : // OR
                          (decode_opcode == 5'h0A) ? 4'h6 : // XOR
                          (decode_opcode == 5'h0B) ? 4'h8 : // SHL
                          (decode_opcode == 5'h0C) ? 4'h9 : // SHR
                          (decode_opcode == 5'h0D) ? 4'hC : // CMP
                          4'h0; // Default to ADD

    // Output assignments
    assign halted = halted_reg;
    assign user_mode = user_mode_reg;
    assign pc = pc_reg;

endmodule
