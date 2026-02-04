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
    output wire [7:0] cpu_flags,
    output wire [2:0] mem_op_width // Output for memory controller (byte/half/word)
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
    reg [31:0] stack_pointer; // Stack pointer
    reg privilege_mode; // 0=user, 1=kernel
    reg halted_reg;
    reg user_mode_reg;

    // CSR Registers
    reg [31:0] mepc;    // Machine Exception Program Counter
    reg [31:0] mcause;  // Machine Cause
    reg [31:0] mstatus; // Machine Status
    reg [31:0] mtvec;   // Machine Trap Vector
    reg [31:0] mscratch; // Machine Scratch
    
    // CSR Interface
    reg [31:0] csr_wdata;
    reg csr_write;
    reg [31:0] csr_rdata;
    wire [11:0] csr_addr = imm12_i;
    wire [31:0] rs1_data = reg_data_a;
    
    // CSR Read Logic
    always @(*) begin
        case (csr_addr)
            12'h341: csr_rdata = mepc;
            12'h342: csr_rdata = mcause;
            12'h300: csr_rdata = mstatus;
            12'h305: csr_rdata = mtvec;
            12'h340: csr_rdata = mscratch;
            // Cycle counters
            12'hC00: csr_rdata = 32'h0; // cycle (low) - TODO: implement counter
            12'hC80: csr_rdata = 32'h0; // cycle (high)
            default: csr_rdata = 32'h0;
        endcase
    end
    
    wire [31:0] operand_a, operand_b;
    wire [31:0] alu_out_wire;
    wire [31:0] alu_result;
    wire [7:0] flags_out;
    
    // Register file signals
    wire [4:0] reg_addr_a, reg_addr_b, reg_addr_w; 
    wire [31:0] reg_data_a, reg_data_b, reg_data_w;
    wire reg_write_en;
    
    // Control signals
    wire [6:0] opcode; 
    wire [4:0] rd, rs1, rs2; 
    wire [2:0] funct3;
    wire [6:0] funct7;
    wire [11:0] imm12_i, imm12_s, imm12_b;
    wire [31:0] imm31_20_u;
    wire [19:0] imm20_j;
    wire [31:0] immediate;
    wire is_load, is_store, is_branch, is_jal, is_jalr, is_op_imm, is_op_reg;
    
    // ----------------------------------------------------------------------
    // OPCODE ASSIGNMENTS (6-bit, fits within 0x00-0x3F range)
    // ----------------------------------------------------------------------
    // 0x00–0x0F: ALU operations
    // 0x10–0x1F: Memory operations
    // 0x20–0x2F: Control/Branch operations
    // 0x30–0x3F: Set/Compare/System operations

    // ALU operation codes (0x00–0x0F)
    // RISC-V Opcodes (7-bit)
    localparam [6:0]
        OP_LOAD   = 7'h03,
        OP_STORE  = 7'h23,
        OP_BRANCH = 7'h63,
        OP_JAL    = 7'h6F,
        OP_JALR   = 7'h67,
        OP_IMM    = 7'h13,
        OP_REG    = 7'h33,
        OP_LUI    = 7'h37,
        OP_AUIPC  = 7'h17,
        OP_SYSTEM = 7'h73;

    // funct3 for Branches
    localparam [2:0]
        F3_BEQ  = 3'h0,
        F3_BNE  = 3'h1,
        F3_BLT  = 3'h4,
        F3_BGE  = 3'h5,
        F3_BLTU = 3'h6,
        F3_BGEU = 3'h7;

    // Flag bit positions (Must match ALU)
    localparam FLAG_CARRY     = 0;
    localparam FLAG_ZERO      = 1;
    localparam FLAG_NEGATIVE  = 2;
    localparam FLAG_OVERFLOW  = 3;

    // ----------------------------------------------------------------------
    // ALU OPCODE TABLE (0x00–0x0F)
    // ----------------------------------------------------------------------
    // | Opcode | Mnemonic | Operation         |
    // |--------|----------|------------------|
    // | 0x00   | ADD      | a + b            |
    // | 0x01   | SUB      | a - b            |
    // | 0x02   | AND      | a & b            |
    // | 0x03   | OR       | a | b            |
    // | 0x04   | XOR      | a ^ b            |
    // | 0x05   | NOT      | ~a               |
    // | 0x06   | SHL      | a << b           |
    // | 0x07   | SHR      | a >> b           |
    // | 0x08   | MUL      | a * b            |
    // | 0x09   | DIV      | a / b            |
    // | 0x0A   | MOD      | a % b            |
    // | 0x0B   | CMP      | compare a, b     |
    // | 0x0C   | SAR      | a >>> b (arith)  |
    // | 0x0D   | ADDI     | a + immediate    |
    // | 0x0E   | SUBI     | a - immediate    |
    // | 0x0F   | CMPI     | compare a, imm   |
    // ----------------------------------------------------------------------
    // Memory OPCODE TABLE (0x10–0x1F)
    // | Opcode | Mnemonic | Operation         |
    // |--------|----------|------------------|
    // | 0x10   | LOAD     | R[rd] = MEM[imm] |
    // | 0x11   | STORE    | MEM[imm] = R[rd] |
    // | 0x12   | LOADI    | R[rd] = imm      |
    // ----------------------------------------------------------------------
    // Control/Branch OPCODE TABLE (0x20–0x2F)
    // | Opcode | Mnemonic | Operation         |
    // |--------|----------|------------------|
    // | 0x20   | JMP      | Jump unconditional|
    // | 0x21   | JZ       | Jump if zero      |
    // | 0x22   | JNZ      | Jump if not zero  |
    // | 0x23   | JC       | Jump if carry     |
    // | 0x24   | JNC      | Jump if no carry  |
    // | 0x25   | JLT      | Jump if less than |
    // | 0x26   | JGE      | Jump if greater/eq|
    // | 0x27   | JLE      | Jump if less/eq   |
    // | 0x28   | CALL     | Call function     |
    // | 0x29   | RET      | Return from call  |
    // | 0x2A   | PUSH     | Push to stack     |
    // | 0x2B   | POP      | Pop from stack    |
    // ----------------------------------------------------------------------
    // Set/Compare/System OPCODE TABLE (0x30–0x3F)
    // | Opcode | Mnemonic | Operation         |
    // |--------|----------|------------------|
    // | 0x30   | SETEQ    | Set if equal      |
    // | 0x31   | SETNE    | Set if not equal  |
    // | 0x32   | SETLT    | Set if less than  |
    // | 0x33   | SETGE    | Set if greater/eq |
    // | 0x34   | SETLE    | Set if less/eq    |
    // | 0x35   | SETGT    | Set if greater    |
    // | 0x3E   | HALT     | Halt processor    |
    // | 0x3F   | INT      | Software interrupt|
    // ----------------------------------------------------------------------
    
    // Instantiate ALU
    alu u_alu (
        .a(operand_a),
        .b(operand_b),
        .opcode((is_branch) ? OP_REG : opcode), // Force ALU to do REG-REG op for branches
        .funct3((is_branch) ? ((funct3 == F3_BEQ || funct3 == F3_BNE) ? 3'h0 : // SUB via funct7
                               (funct3 == F3_BLT || funct3 == F3_BGE) ? 3'h2 : // SLT
                               (funct3 == F3_BLTU || funct3 == F3_BGEU) ? 3'h3 : // SLTU
                               3'h0) : funct3),
        .funct7((is_branch && (funct3 == F3_BEQ || funct3 == F3_BNE)) ? 7'h20 : funct7), // SUB for BEQ/BNE
        .flags_in(flags_reg),
        .result(alu_out_wire),
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
            
            // CSR Reset
            mepc <= 32'h0;
            mcause <= 32'h0;
            mstatus <= 32'h00001800; // MPP=11 (Machine mode)
            mtvec <= 32'h0;
            mscratch <= 32'h0;
            csr_write <= 1'b0;
        end else if (mem_ready && !halted_reg) begin
            state <= next_state;
            
            
            case (state)
                FETCH: begin
                    if (mem_ready) begin
                        instruction_reg <= data_bus;
                        $display("==== INSTR_START ==== PC=0x%08x IS=0x%08x ====", pc_reg, data_bus);
                        $display("FETCH_DONE: PC=0x%x, fetched instruction=0x%x", pc_reg, data_bus);
                        pc_reg <= pc_reg + 32'h4;
                    end
                end
                
                DECODE: begin
                    $display("DECODE_START: PC=0x%08x, IS=0x%08x", pc_reg, instruction_reg);
                    $display("DECODE_FIELDS: Opcode=0x%02x, rd=%d, rs1=%d, rs2=%d, imm=0x%08x", opcode, rd, rs1, rs2, immediate);
                    $display("DECODE_REGS_BEFORE: R%d=0x%08x, R%d=0x%08x", rs1, reg_data_a, rs2, reg_data_b);
                    $display("DECODE_FLAGS_BEFORE: C=%b Z=%b N=%b V=%b", flags_reg[0], flags_reg[1], flags_reg[2], flags_reg[3]);
                    // Decode happens combinatorially
                end
                
                EXECUTE: begin
                    $display("EXECUTE_START: PC=0x%08x, IS=0x%08x, Opcode=0x%02x", pc_reg, instruction_reg, opcode);
                    
                    // ------ BEGIN: Handle the result of ALU operations-----
                    alu_result_reg <= alu_out_wire;
                    
                    // Update flags for ALU operations
                    if (opcode == OP_REG || opcode == OP_IMM) begin
                        flags_reg <= flags_out;
                        $display("EXECUTE_FLAGS_AFTER: C=%b Z=%b N=%b V=%b", 
                                flags_out[0], flags_out[1], flags_out[2], flags_out[3]);
                    end

                    // Handle CSR operations
                    if (opcode == OP_SYSTEM) begin
                        if (funct3 != 3'h0) begin // CSR Instructions
                            // Calculate write value
                            case (funct3)
                                3'h1: csr_wdata = rs1_data; // CSRRW
                                3'h2: csr_wdata = csr_rdata | rs1_data; // CSRRS
                                3'h3: csr_wdata = csr_rdata & ~rs1_data; // CSRRC
                            endcase
                            
                            // Perform Write
                            case (csr_addr)
                                12'h341: mepc <= csr_wdata;
                                12'h342: mcause <= csr_wdata;
                                12'h300: mstatus <= csr_wdata;
                                12'h305: mtvec <= csr_wdata;
                                12'h340: mscratch <= csr_wdata;
                            endcase
                            
                            alu_result_reg <= csr_rdata; // Read old value into RD
                            
                            $display("CSR_OP: addr=0x%03x, wdata=0x%08x, rdata=0x%08x", imm12_i, csr_wdata, csr_rdata);
                        end else if (instruction_reg[31:20] == 12'h1) begin // EBREAK
                            // Use standard RISC-V Exception handling:
                            // 1. Save PC to mepc
                            // 2. Set mcause to 3 (Breakpoint)
                            // 3. Jump to trap vector (mtvec)
                            // For this simplified core, we'll just HALT as before but log it properly
                            halted_reg <= 1'b1;
                            mepc <= pc_reg;
                            mcause <= 32'd3; // Breakpoint
                            $display("EXCEPTION: EBREAK at PC=0x%08x", pc_reg - 4);
                        end else if (instruction_reg[31:20] == 12'h302) begin // MRET
                             pc_reg <= mepc;
                             $display("MRET: Returning to PC=0x%08x", mepc);
                        end
                    end
                    
                    // Branch/jump PC update handled in FETCH for next cycle
                    if ((is_branch && branch_taken) || is_jal || is_jalr) begin
                        pc_reg <= (is_jalr) ? (alu_result & ~32'h1) : (pc_reg - 4 + immediate); // jalr/branch use current PC-4 because PC was already incremented
                        $display("DEBUG CPU: Jump/Branch taken to PC=0x%x", 
                                (is_jalr) ? (alu_result & ~32'h1) : (pc_reg - 4 + immediate));
                    end
                    
                    $display("EXECUTE_DONE: PC=0x%08x, IS=0x%08x Opcode=0x%02x, rd=%d, rs1=%d, rs2=%d, imm=0x%08x", pc_reg, instruction_reg, opcode, rd, rs1, rs2, immediate);
                end
                
                MEMORY: begin
                    $display("MEMORY_START: PC=0x%08x, IS=0x%08x", pc_reg, instruction_reg);
                    if (is_load) begin
                        memory_data_reg <= data_bus;
                        $display("MEMORY_LOAD: addr=0x%08x, data=0x%08x", alu_result, data_bus);
                    end
                    if (is_store) begin
                        $display("MEMORY_STORE: addr=0x%08x, data=0x%08x", alu_result, reg_data_b);
                    end
                end
                
                WRITEBACK: begin
                    $display("WRITEBACK_START: PC=0x%08x, IS=0x%08x", pc_reg, instruction_reg);
                    // Write back happens combinatorially
                    if (reg_write_en) begin
                        $display("WRITEBACK_REG: R%d <= 0x%08x", rd, reg_data_w);
                    end
                    $display("==== INSTR_END ==== PC=0x%08x ====", pc_reg);
                end
            endcase
        end
    end
    
    // Next state logic
    always @(*) begin
        case (state)
            FETCH:     next_state = DECODE;
            DECODE:    next_state = EXECUTE;
            EXECUTE:   next_state = (is_load || is_store) ? MEMORY : WRITEBACK;
            MEMORY:    next_state = WRITEBACK;
            WRITEBACK: next_state = FETCH;
            default:   next_state = FETCH;
        endcase
    end
    
    // Instruction decode
    // 6 bit opcodes
    // Instruction decode (RISC-V)
    assign opcode = instruction_reg[6:0];
    assign rd     = instruction_reg[11:7];
    assign funct3 = instruction_reg[14:12];
    assign rs1    = instruction_reg[19:15];
    assign rs2    = instruction_reg[24:20];
    assign funct7 = instruction_reg[31:25];

    // Immediates
    assign imm12_i = instruction_reg[31:20];
    assign imm12_s = {instruction_reg[31:25], instruction_reg[11:7]};
    assign imm12_b = {instruction_reg[31], instruction_reg[7], instruction_reg[30:25], instruction_reg[11:8]};
    assign imm31_20_u = {instruction_reg[31:12], 12'h0};
    assign imm20_j = {instruction_reg[31], instruction_reg[19:12], instruction_reg[20], instruction_reg[30:21]};

    assign immediate = (opcode == OP_IMM || opcode == OP_LOAD || opcode == OP_JALR) ? {{20{imm12_i[11]}}, imm12_i} :
                       (opcode == OP_STORE)  ? {{20{imm12_s[11]}}, imm12_s} :
                       (opcode == OP_BRANCH) ? {{19{imm12_b[11]}}, imm12_b, 1'b0} :
                       (opcode == OP_LUI || opcode == OP_AUIPC) ? imm31_20_u :
                       (opcode == OP_JAL)    ? {{11{imm20_j[19]}}, imm20_j, 1'b0} :
                       32'h0;

    // Control signal generation
    assign is_load   = (opcode == OP_LOAD);
    assign is_store  = (opcode == OP_STORE);
    assign is_branch = (opcode == OP_BRANCH);
    assign is_jal    = (opcode == OP_JAL);
    assign is_jalr   = (opcode == OP_JALR);
    assign is_op_imm = (opcode == OP_IMM);
    assign is_op_reg = (opcode == OP_REG);

    // Branch condition logic - uses current ALU output flags (combinatorial)
    wire branch_taken =
        (funct3 == F3_BEQ)  ? (flags_out[FLAG_ZERO]) : // Z
        (funct3 == F3_BNE)  ? (~flags_out[FLAG_ZERO]) : // !Z
        (funct3 == F3_BLT)  ? (alu_out_wire[0]) : // SLT result (1 if taken)
        (funct3 == F3_BGE)  ? (~alu_out_wire[0]) : // !SLT
        (funct3 == F3_BLTU) ? (alu_out_wire[0]) : // SLTU result
        (funct3 == F3_BGEU) ? (~alu_out_wire[0]) : // !SLTU
        1'b0;

    // ALU connections
    assign operand_a = (opcode == OP_AUIPC) ? (pc_reg - 4) : reg_data_a;
    // For branches, we compare rs1 and rs2. rs2 is on reg_data_b.
    assign operand_b = (opcode == OP_REG || opcode == OP_BRANCH) ? reg_data_b : immediate;
    
    // Register file connections
    assign reg_addr_a = rs1;
    assign reg_addr_b = (opcode == OP_STORE || opcode == OP_BRANCH) ? rs2 : rs2; // Standard RS2
    assign reg_addr_w = rd;   
    // Load Data Formatting Logic
    reg [31:0] load_data_formatted;
    wire [1:0] byte_offset = alu_result_reg[1:0];
    wire [7:0] byte_val = (byte_offset == 2'b00) ? memory_data_reg[7:0] :
                          (byte_offset == 2'b01) ? memory_data_reg[15:8] :
                          (byte_offset == 2'b10) ? memory_data_reg[23:16] :
                                                   memory_data_reg[31:24];
    wire [15:0] half_val = (byte_offset[1] == 1'b0) ? memory_data_reg[15:0] : memory_data_reg[31:16];

    always @(*) begin
        if (state == WRITEBACK && is_load) begin
            case (funct3)
                3'b000: load_data_formatted = {{24{byte_val[7]}}, byte_val}; // LB
                3'b001: load_data_formatted = {{16{half_val[15]}}, half_val}; // LH
                3'b010: load_data_formatted = memory_data_reg; // LW
                3'b100: load_data_formatted = {24'b0, byte_val}; // LBU
                3'b101: load_data_formatted = {16'b0, half_val}; // LHU
                default: load_data_formatted = memory_data_reg;
            endcase
        end else begin
            load_data_formatted = memory_data_reg;
        end
    end

    assign reg_data_w = (state == WRITEBACK) ? 
                       ((is_load) ? load_data_formatted :
                        (is_jal || is_jalr) ? pc_reg : // pc_reg already points to next instruction
                        alu_result_reg) : 32'h0;
    // DEBUG: Show what is being written to the register file
    always @(*) begin
        if (state == WRITEBACK && reg_write_en) begin
            $display("REGISTER_FILE_WRITE: R%d <= 0x%08x (opcode=0x%02x)", rd, reg_data_w, opcode);
        end
    end
    
    assign reg_write_en = (state == WRITEBACK) && 
                          (rd != 5'h0) && // x0 is always zero
                          (is_load || is_jal || is_jalr || is_op_imm || is_op_reg || opcode == OP_LUI || opcode == OP_AUIPC || opcode == OP_SYSTEM);

                         

    // Memory interface with intelligent addressing
    // Memory interface
    assign addr_bus = (state == FETCH) ? pc_reg : 
                     (state == MEMORY) ? alu_result : pc_reg;
    
    assign data_bus = (state == MEMORY && is_store && mem_write) ? reg_data_b : 32'hZZZZZZZZ;
    
    assign mem_read = (state == FETCH) ? 1'b1 : 
                     (state == MEMORY && is_load) ? 1'b1 : 1'b0;
    
    assign mem_write = (state == MEMORY && is_store) ? 1'b1 : 1'b0;
    
    // Debug outputs
    always @(posedge clk) begin
        if (!rst_n) begin
            // Reset debug state
        end else begin
            //$display("DEBUG CPU State: state=%b, next_state=%b, opcode=0x%h, pc=0x%h, alu_result_reg=0x%h, reg_write_en=%b, reg_addr_w=%d, reg_data_w=0x%h");
            if (state == EXECUTE) begin
                $display("DEBUG_EXECUTE: PC=0x%x, Opcode=%h, rd=%d, rs1=%d, rs2=%d, imm=%h", pc_reg, opcode, rd, rs1, rs2, immediate);
                if (opcode == 6'h04 || opcode == 6'h05) begin
                    $display("DEBUG CPU ALU: %s rd=%d, rs1=%d, val2=%d, result=%d", opcode == 6'h04 ? "ADD" : "ADDI", rd, rs1, opcode == 6'h04 ? reg_data_b : immediate, alu_result);
               end
            end else if (state == WRITEBACK && reg_write_en) begin
                $display("DEBUG CPU Writeback: Writing %d to R%d", reg_data_w, reg_addr_w);
            end
        end
    end
    
    // I/O interface (simplified)
    assign interrupt_ack = 1'b0;
    assign io_addr = 8'h00;
    assign io_read = 1'b0;
    assign io_write = 1'b0;
    
    // Status outputs
    assign halted = halted_reg;
    assign alu_result = alu_result_reg;
    assign user_mode = user_mode_reg;
    assign cpu_flags = flags_reg;
    assign mem_op_width = funct3; // Expose funct3 for memory controller

endmodule
