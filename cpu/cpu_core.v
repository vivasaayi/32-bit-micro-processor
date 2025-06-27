/**
 * Simplified 32-Bit CPU Core
 * 
 * A simplified implementation for testing that separates instruction fetch
 * from data memory operations using a state machine approach.
 */

module cpu_core (
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
    
    // I/O interface
    output wire [7:0] io_addr,
    inout wire [7:0] io_data,
    output wire io_read,
    output wire io_write,
    
    // Status outputs
    output wire halted,
    output wire user_mode
);

    // CPU state machine states
    localparam [2:0] FETCH    = 3'b000,
                     DECODE   = 3'b001,
                     EXECUTE  = 3'b010,
                     MEMORY   = 3'b011,
                     WRITEBACK = 3'b100;
    
    reg [2:0] state, next_state;
    
    // Registers and internal signals
    reg [31:0] pc_reg;
    reg [31:0] instruction_reg;
    reg [31:0] alu_result_reg;
    reg [31:0] memory_data_reg;
    reg halted_reg;
    reg user_mode_reg;
    
    // ALU signals
    wire [31:0] alu_a, alu_b, alu_result;
    wire [3:0] alu_op;
    wire [7:0] flags_in, flags_out;
    
    // Register file signals
    wire [3:0] reg_addr_a, reg_addr_b, reg_addr_w;
    wire [31:0] reg_data_a, reg_data_b, reg_data_w;
    wire reg_write_en;
    
    // Control signals
    wire [4:0] opcode;
    wire [3:0] rd, rs1, rs2;
    wire [19:0] imm20;
    wire [11:0] imm12;
    wire [31:0] immediate;
    wire is_immediate_inst, is_load_store, is_branch_jump;
    
    // Instantiate ALU
    alu alu_inst (
        .a(alu_a),
        .b(alu_b),
        .op(alu_op),
        .flags_in(flags_in),
        .result(alu_result),
        .flags_out(flags_out)
    );
    
    // Instantiate register file
    register_file reg_file_inst (
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
    
    // State machine
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= FETCH;
            pc_reg <= 32'h00000000;
            instruction_reg <= 32'h00000000;
            alu_result_reg <= 32'h00000000;
            memory_data_reg <= 32'h00000000;
            halted_reg <= 1'b0;
            user_mode_reg <= 1'b0;
        end else if (mem_ready && !halted_reg) begin
            state <= next_state;
            
            case (state)
                FETCH: begin
                    if (mem_ready) begin
                        instruction_reg <= data_bus;
                        pc_reg <= pc_reg + 32'h4;
                    end
                end
                
                DECODE: begin
                    // Decode happens combinatorially
                end
                
                EXECUTE: begin
                    alu_result_reg <= alu_result;
                    if (opcode == 5'h1F) begin // HALT
                        halted_reg <= 1'b1;
                    end
                    // Debug output for ALU operations
                    if (opcode == 5'h04 || opcode == 5'h05) begin // ADD/ADDI
                        $display("DEBUG ALU: ADD/ADDI - op=%s R%d = R%d + %s%d => %d", 
                                (opcode == 5'h04) ? "ADD" : "ADDI",
                                rd, rs1, 
                                (opcode == 5'h04) ? "R" : "#",
                                (opcode == 5'h04) ? rs2 : immediate,
                                alu_result);
                    end
                end
                
                MEMORY: begin
                    if (is_load_store && opcode == 5'h02) begin // LOAD
                        memory_data_reg <= data_bus;
                        $display("DEBUG CPU: LOAD from addr=0x%x, data=%d", immediate, data_bus);
                    end
                    if (opcode == 5'h03) begin // STORE
                        $display("DEBUG CPU: STORE R%d=%d to addr=0x%x, mem_write=%b, data_bus=0x%x", 
                                rd, reg_data_a, immediate, mem_write, data_bus);
                    end
                end
                
                WRITEBACK: begin
                    // Write back happens combinatorially
                end
            endcase
        end
    end
    
    // Next state logic
    always @(*) begin
        case (state)
            FETCH:     next_state = DECODE;
            DECODE:    next_state = EXECUTE;
            EXECUTE:   next_state = is_load_store ? MEMORY : WRITEBACK;
            MEMORY:    next_state = WRITEBACK;
            WRITEBACK: next_state = FETCH;
            default:   next_state = FETCH;
        endcase
    end
    
    // Instruction decode
    assign opcode = instruction_reg[31:27];
    assign rd = instruction_reg[23:20];
    assign rs1 = instruction_reg[19:16];  
    assign rs2 = instruction_reg[15:12];
    assign imm20 = instruction_reg[19:0];
    assign imm12 = instruction_reg[11:0];
    
    // Control signal generation
    assign is_immediate_inst = (opcode == 5'h01) || (opcode == 5'h05) || (opcode == 5'h07);
    assign is_load_store = (opcode == 5'h02) || (opcode == 5'h03);
    assign is_branch_jump = (opcode >= 5'h0E) && (opcode <= 5'h12);
    
    // Immediate value selection
    assign immediate = (is_load_store) ? {12'h000, imm20} :           // Zero-extend for addresses
                      (opcode == 5'h01) ? {12'h000, imm20} :       // Zero-extend for LOADI
                      ((opcode == 5'h05) || (opcode == 5'h07)) ? {{12{imm20[19]}}, imm20} : // Sign-extend for ADDI/SUBI
                      {{20{imm12[11]}}, imm12};                     // Sign-extend based on imm12 for other ops
    
    // ALU connections
    assign alu_a = reg_data_a;
    assign alu_b = is_immediate_inst ? immediate : reg_data_b;
    assign alu_op = (opcode == 5'h04 || opcode == 5'h05) ? 4'h0 : // ADD/ADDI
                   (opcode == 5'h06 || opcode == 5'h07) ? 4'h1 : // SUB/SUBI
                   (opcode == 5'h08) ? 4'h4 : // AND
                   (opcode == 5'h09) ? 4'h5 : // OR
                   (opcode == 5'h0A) ? 4'h6 : // XOR
                   (opcode == 5'h0D) ? 4'hC : // CMP
                   4'h0; // Default ADD
    
    assign flags_in = 8'h00; // Simplified
    
    // Register file connections
    assign reg_addr_a = (opcode == 5'h03) ? rd : rs1;
    assign reg_addr_b = rs2;
    assign reg_addr_w = rd;
    assign reg_data_w = (state == WRITEBACK) ? 
                       ((opcode == 5'h02) ? memory_data_reg : alu_result_reg) : 32'h0;
    assign reg_write_en = (state == WRITEBACK) && 
                         !(opcode == 5'h03) && !(opcode == 5'h1F) && !is_branch_jump;

    // Memory interface with debug
    assign addr_bus = (state == FETCH) ? pc_reg : 
                     (state == MEMORY && is_load_store) ? immediate : 
                     pc_reg;
    
    assign data_bus = (state == MEMORY && opcode == 5'h03 && mem_write) ? reg_data_a : 32'hZZZZZZZZ;
    
    assign mem_read = (state == FETCH) ? 1'b1 : 
                     (state == MEMORY && opcode == 5'h02) ? 1'b1 : 1'b0;
    
    assign mem_write = (state == MEMORY && opcode == 5'h03) ? 1'b1 : 1'b0;
    
    // Debug outputs
    always @(posedge clk) begin
        if (!rst_n) begin
            // Reset debug state
        end else if (state == EXECUTE) begin
            $display("DEBUG CPU Execute: PC=0x%x, Opcode=%h, rd=%d, rs1=%d, rs2=%d, imm=%h",
                    pc_reg, opcode, rd, rs1, rs2, immediate);
            if (opcode == 5'h04 || opcode == 5'h05) begin
                $display("DEBUG CPU ALU: %s rd=%d, rs1=%d, val2=%d, result=%d",
                        opcode == 5'h04 ? "ADD" : "ADDI",
                        rd, rs1, opcode == 5'h04 ? reg_data_b : immediate,
                        alu_result);
            end
        end else if (state == WRITEBACK && reg_write_en) begin
            $display("DEBUG CPU Writeback: Writing %d to R%d", reg_data_w, reg_addr_w);
        end
    end
    
    // I/O interface (simplified)
    assign interrupt_ack = 1'b0;
    assign io_addr = 8'h00;
    assign io_read = 1'b0;
    assign io_write = 1'b0;
    
    // Status outputs
    assign halted = halted_reg;
    assign user_mode = user_mode_reg;

endmodule
