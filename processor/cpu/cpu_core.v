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
    output wire user_mode,
    output wire [7:0] cpu_flags
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
    reg [7:0] flags_reg;  // Store ALU flags
    reg [31:0] stack_pointer; // Stack pointer (R30 equivalent)
    reg [31:0] saved_pc; // For function calls and interrupts
    reg privilege_mode; // 0=user, 1=kernel
    reg halted_reg;
    reg user_mode_reg;
    
    // ALU signals
    wire [31:0] alu_a, alu_b, alu_result;
    wire [4:0] alu_op;
    wire [7:0] flags_in, flags_out;
    
    // Register file signals
    wire [4:0] reg_addr_a, reg_addr_b, reg_addr_w; 
    wire [31:0] reg_data_a, reg_data_b, reg_data_w;
    wire reg_write_en;
    
    // Control signals
    wire [5:0] opcode; // RAJAN: 6 bit opcode
    wire [4:0] rd, rs1, rs2;  // RAJAN:  5-bit register addresses
    wire [19:0] imm20;
    wire [11:0] imm12;
    wire [31:0] immediate;
    wire is_immediate_inst, is_load_store, is_branch_jump;
    
    // Branch/jump opcodes
    localparam [5:0] 
        OP_CMP   = 6'h11,
        OP_JMP   = 6'h12,
        OP_JZ    = 6'h13,
        OP_JNZ   = 6'h14,
        OP_JC    = 6'h15,
        OP_JNC   = 6'h16,
        OP_JLT   = 6'h17,
        OP_JGE   = 6'h18,
        OP_JLE   = 6'h19,
        OP_JN    = 6'h1A,
        OP_CALL  = 6'h1B,
        OP_RET   = 6'h1C,
        OP_PUSH  = 6'h1D,
        OP_POP   = 6'h1E,
        OP_HALT  = 6'h1F;

    // Set/compare instruction opcodes
    localparam [5:0]
        OP_SETEQ = 6'h20,
        OP_SETNE = 6'h21,
        OP_SETLT = 6'h22,
        OP_SETGE = 6'h23,
        OP_SETLE = 6'h24,
        OP_SETGT = 6'h25;

    // ALU operation codes (extracted for clarity)
    localparam [5:0]
        ALU_ADD  = 6'h00,
        ALU_SUB  = 6'h01,
        ALU_AND  = 6'h04,
        ALU_OR   = 6'h05,
        ALU_XOR  = 6'h06,
        ALU_NOT  = 6'h07,
        ALU_SHL  = 6'h08,
        ALU_SHR  = 6'h09,
        ALU_CMP  = 6'h0C,
        ALU_MUL  = 6'h0E,
        ALU_DIV  = 6'h0F,
        ALU_MOD  = 6'h10;
    
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
            pc_reg <= 32'h00008000;  // Start execution at 0x8000
            instruction_reg <= 32'h00000000;
            alu_result_reg <= 32'h00000000;
            memory_data_reg <= 32'h00000000;
            flags_reg <= 8'h00;
            stack_pointer <= 32'h000F0000; // Initialize stack to high memory
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
                    $display("DEBUG CPU Execute: Instruction opcode=%h, alu_result=%d, alu_result_reg will be set to %d", 
                            opcode, alu_result, alu_result);
                    // Update flags for ALU operations
                    if (opcode == 6'h04 || opcode == 6'h05 || opcode == 6'h06 || opcode == 6'h07 || 
                        opcode == 6'h08 || opcode == 6'h09 || opcode == 6'h0A || opcode == 6'h0D) begin
                        flags_reg <= flags_out;
                        $display("DEBUG CPU: Flags updated to C=%b Z=%b N=%b V=%b", 
                                flags_out[0], flags_out[1], flags_out[2], flags_out[3]);
                    end
                    // Handle set instructions
                    $display("DEBUG: Checking SET condition: opcode=%h, OP_SETEQ=%h, condition=%b", 
                            opcode, OP_SETEQ, (opcode == OP_SETEQ || opcode == OP_SETNE || opcode == OP_SETLT ||
                            opcode == OP_SETGE || opcode == OP_SETLE || opcode == OP_SETGT));
                    if (opcode == OP_SETEQ || opcode == OP_SETNE || opcode == OP_SETLT ||
                        opcode == OP_SETGE || opcode == OP_SETLE || opcode == OP_SETGT) begin
                        case (opcode)
                            OP_SETEQ: alu_result_reg <= flags_reg[1] ? 32'h1 : 32'h0;  // Z flag
                            OP_SETNE: alu_result_reg <= !flags_reg[1] ? 32'h1 : 32'h0; // !Z flag
                            OP_SETLT: alu_result_reg <= flags_reg[2] ? 32'h1 : 32'h0;  // N flag
                            OP_SETGE: alu_result_reg <= !flags_reg[2] ? 32'h1 : 32'h0; // !N flag
                            OP_SETLE: alu_result_reg <= (flags_reg[2] || flags_reg[1]) ? 32'h1 : 32'h0; // N || Z
                            OP_SETGT: alu_result_reg <= (!flags_reg[2] && !flags_reg[1]) ? 32'h1 : 32'h0; // !N && !Z
                            // No default case - leave alu_result_reg as set by line 134
                        endcase
                        $display("DEBUG CPU: SET instruction - opcode=%h, flags=0x%h, result=%d", 
                                opcode, flags_reg, alu_result_reg);
                    end
                    if (opcode == 6'h1F) begin // HALT
                        halted_reg <= 1'b1;
                    end
                    // Branch/jump PC update
                    if (is_branch_jump && branch_taken) begin
                        // PC-relative branch: immediate is offset in words (9-bit signed)
                        pc_reg <= pc_reg + ({{23{imm12[8]}}, imm12} << 2);
                        $display("DEBUG CPU: Branch taken from PC=0x%x to PC=0x%x, offset=%d", 
                                pc_reg, pc_reg + ({{23{imm12[8]}}, imm12} << 2), {{23{imm12[8]}}, imm12});
                    end else if (is_branch_jump && !branch_taken) begin
                        $display("DEBUG CPU: Branch not taken at PC=0x%x, condition failed", pc_reg);
                    end
                    // Debug output for ALU operations
                    if (opcode == 6'h04 || opcode == 6'h05) begin // ADD/ADDI
                        $display("DEBUG ALU: ADD/ADDI - op=%s R%d = R%d + %s%d => %d", 
                                (opcode == 6'h04) ? "ADD" : "ADDI",
                                rd, rs1, 
                                (opcode == 6'h04) ? "R" : "#",
                                (opcode == 6'h04) ? rs2 : immediate,
                                alu_result);
                    end
                end
                
                MEMORY: begin
                    if (is_load_store && opcode == 6'h02) begin // LOAD
                        memory_data_reg <= data_bus;
                        $display("DEBUG CPU: LOAD from addr=0x%x, data=%d", immediate, data_bus);
                    end
                    if (opcode == 6'h03) begin // STORE
                        $display("DEBUG CPU: STORE R%d=%d to addr=0x%x, mem_write=%b, data_bus=0x%x", 
                                store_direct_addr ? rd : rs1, reg_data_a, immediate, mem_write, data_bus);
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
    // 6 bit opcodes
    assign opcode = instruction_reg[31:26]; 
    assign rd = instruction_reg[23:19];   // 5-bit register address
    assign rs1 = instruction_reg[18:14];  // 5-bit register address
    assign rs2 = instruction_reg[13:9];   // 5-bit register address
    assign imm20 = instruction_reg[18:0]; // 19-bit immediate (reduced from 20)
    assign imm12 = instruction_reg[8:0];  // 9-bit immediate (reduced from 12)
    
    // For ADDI/SUBI, use 20-bit immediate and rs1 from [19:16]
    wire [31:0] addi_subi_imm = {{12{instruction_reg[19]}}, instruction_reg[19:0]};
    
    // Control signal generation
    assign is_immediate_inst = (opcode == 6'h01) || (opcode == 6'h05) || (opcode == 6'h07);
    assign is_load_store = (opcode == 6'h02) || (opcode == 6'h03);
    assign is_branch_jump = (opcode >= OP_JMP && opcode <= OP_JLE);
    
    // Enhanced memory addressing intelligence
    wire is_log_buffer_access = (immediate >= 32'h3000) && (immediate < 32'h5000);
    wire is_stack_access = (immediate >= 32'h7000) && (immediate < 32'h8000);
    wire is_io_access = (immediate >= 32'h8000) && (immediate < 32'h9000);
    
    // Detect STORE with direct addressing (20-bit immediate format)
    // Format: opcode(5) | 000(3) | rs(4) | address(20)
    wire store_direct_addr = (opcode == 6'h03) && (instruction_reg[26:24] == 3'b000);
    
    // Optimize for known memory regions
    wire use_optimized_addressing = is_log_buffer_access || is_stack_access;
    
    // Branch condition logic
    wire branch_taken =
        (opcode == OP_JMP) ? 1'b1 :
        (opcode == OP_JZ)  ? (flags_reg[1]) : // Z flag
        (opcode == OP_JNZ) ? (~flags_reg[1]) :
        (opcode == OP_JC)  ? (flags_reg[0]) : // C flag
        (opcode == OP_JNC) ? (~flags_reg[0]) :
        (opcode == OP_JLT) ? (flags_reg[2]) : // N flag  
        (opcode == OP_JGE) ? (~flags_reg[2]) : // !N
        (opcode == OP_JLE) ? (flags_reg[1] | flags_reg[2]) : // Z | N
        1'b0;

    // Immediate value selection
    assign immediate = (opcode == 6'h02) ? {13'h0000, imm20} :                         // LOAD: 19-bit address
                      (opcode == 6'h03 && store_direct_addr) ? {13'h0000, imm20} :     // STORE direct: 19-bit address  
                      (opcode == 6'h03 && !store_direct_addr) ? {{23{imm12[8]}}, imm12} : // STORE reg+offset: 9-bit offset
                      (opcode == 6'h01) ? {13'h0000, imm20} :                          // LOADI: 19-bit immediate
                      ((opcode == 6'h05) || (opcode == 6'h07)) ? {{23{imm12[8]}}, imm12} : // ADDI/SUBI: 9-bit signed
                      {{23{imm12[8]}}, imm12};                                         // Default: 9-bit signed
    
    // ALU connections
    assign alu_a = reg_data_a;
    assign alu_b = is_immediate_inst ? immediate : reg_data_b;
    assign alu_op = (opcode == 6'h04 || opcode == 6'h05) ? ALU_ADD : // ADD/ADDI
                   (opcode == 6'h06 || opcode == 6'h07) ? ALU_SUB : // SUB/SUBI
                   (opcode == 6'h08) ? ALU_MUL :                     // MUL
                   (opcode == 6'h09) ? ALU_DIV :                     // DIV
                   (opcode == 6'h0A) ? ALU_MOD :                     // MOD
                   (opcode == 6'h0B) ? ALU_AND :                     // AND
                   (opcode == 6'h0C) ? ALU_OR  :                     // OR
                   (opcode == 6'h0D) ? ALU_XOR :                     // XOR
                   (opcode == 6'h0E) ? ALU_NOT :                     // NOT
                   (opcode == 6'h0F) ? ALU_SHL :                     // SHL
                   (opcode == 6'h10) ? ALU_SHR :                     // SHR
                   (opcode == 6'h11) ? ALU_CMP :                     // CMP
                   ALU_ADD; // Default ADD
    
    assign flags_in = flags_reg; // Use stored flags as input to ALU
    
    // Register file connections
    assign reg_addr_a = (opcode == 6'h03) ? rd : rs1;  // For STORE, source data is in rd; others use rs1
    assign reg_addr_b = (opcode == 6'h03 && !store_direct_addr) ? rs1 : rs2;  // For STORE register addressing, address base is in rs1
    assign reg_addr_w = rd;   // Always use rd for write destination
    assign reg_data_w = (state == WRITEBACK) ? 
                       ((opcode == 6'h02) ? memory_data_reg : alu_result_reg) : 32'h0;
    assign reg_write_en = (state == WRITEBACK) && 
                         !(opcode == 6'h03) && !(opcode == 6'h1F) && !is_branch_jump ||
                         (state == WRITEBACK) && (opcode == OP_SETEQ || opcode == OP_SETNE || 
                          opcode == OP_SETLT || opcode == OP_SETGE || opcode == OP_SETLE || opcode == OP_SETGT);

    // Memory interface with intelligent addressing
    assign addr_bus = (state == FETCH) ? pc_reg : 
                     (state == MEMORY && is_load_store && store_direct_addr) ? immediate :     // Direct addressing: use immediate as address
                     (state == MEMORY && is_load_store && !store_direct_addr) ? (reg_data_b + immediate) : // Register+offset: base + offset
                     (state == MEMORY && is_load_store) ? immediate :         // LOAD: always direct addressing
                     pc_reg;
    
    assign data_bus = (state == MEMORY && opcode == 6'h03 && mem_write) ? reg_data_a : 32'hZZZZZZZZ;
    
    assign mem_read = (state == FETCH) ? 1'b1 : 
                     (state == MEMORY && opcode == 6'h02) ? 1'b1 : 1'b0;
    
    assign mem_write = (state == MEMORY && opcode == 6'h03) ? 1'b1 : 1'b0;
    
    // Debug outputs
    always @(posedge clk) begin
        if (!rst_n) begin
            // Reset debug state
        end else if (state == EXECUTE) begin
            $display("DEBUG CPU Execute: PC=0x%x, Opcode=%h, rd=%d, rs1=%d, rs2=%d, imm=%h",
                    pc_reg, opcode, rd, rs1, rs2, immediate);
            if (opcode == 6'h04 || opcode == 6'h05) begin
                $display("DEBUG CPU ALU: %s rd=%d, rs1=%d, val2=%d, result=%d",
                        opcode == 6'h04 ? "ADD" : "ADDI",
                        rd, rs1, opcode == 6'h04 ? reg_data_b : immediate,
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
    assign cpu_flags = flags_reg;

endmodule
