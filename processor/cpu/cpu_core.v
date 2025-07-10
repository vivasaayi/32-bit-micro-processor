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
    wire [5:0] opcode; 
    wire [4:0] rd, rs1, rs2; 
    wire [19:0] imm20;
    wire [11:0] imm12;
    wire [31:0] immediate;
    wire is_immediate_inst, is_load_store, is_branch_jump;
    
    // ----------------------------------------------------------------------
    // OPCODE ASSIGNMENTS (6-bit, fits within 0x00-0x3F range)
    // ----------------------------------------------------------------------
    // 0x00–0x0F: ALU operations
    // 0x10–0x1F: Memory operations
    // 0x20–0x2F: Control/Branch operations
    // 0x30–0x3F: Set/Compare/System operations

    // ALU operation codes (0x00–0x0F)
    localparam [5:0]
        ALU_ADD  = 6'h00,
        ALU_SUB  = 6'h01,
        ALU_AND  = 6'h02,
        ALU_OR   = 6'h03,
        ALU_XOR  = 6'h04,
        ALU_NOT  = 6'h05,
        ALU_SHL  = 6'h06,
        ALU_SHR  = 6'h07,
        ALU_MUL  = 6'h08,
        ALU_DIV  = 6'h09,
        ALU_MOD  = 6'h0A,
        ALU_CMP  = 6'h0B,
        ALU_SAR  = 6'h0C; // Arithmetic shift right

    // Memory operation codes (0x10–0x1F)
    localparam [5:0]
        MEM_LOAD  = 6'h10,
        MEM_STORE = 6'h11,
        MEM_LOADI = 6'h12; // LOADI: Load immediate value into register

    // Control/Branch opcodes (0x20–0x2F)
    localparam [5:0]
        OP_JMP   = 6'h20,
        OP_JZ    = 6'h21,
        OP_JNZ   = 6'h22,
        OP_JC    = 6'h23,
        OP_JNC   = 6'h24,
        OP_JLT   = 6'h25,
        OP_JGE   = 6'h26,
        OP_JLE   = 6'h27,
        OP_CALL  = 6'h28,
        OP_RET   = 6'h29,
        OP_PUSH  = 6'h2A,
        OP_POP   = 6'h2B;

    // Set/Compare/System opcodes (0x30–0x3F)
    localparam [5:0]
        OP_SETEQ = 6'h30,
        OP_SETNE = 6'h31,
        OP_SETLT = 6'h32,
        OP_SETGE = 6'h33,
        OP_SETLE = 6'h34,
        OP_SETGT = 6'h35,
        OP_HALT  = 6'h3E,
        OP_INT   = 6'h3F;

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
                    $display("FETCH_BEGIN: PC=0x%x, IS=0x%x Opcode=%h, rd=%d, rs1=%d, rs2=%d, imm=%h, alu_result=%d", pc_reg, instruction_reg, opcode, rd, rs1, rs2, immediate, alu_result);
                    if (mem_ready) begin
                        instruction_reg <= data_bus;
                        pc_reg <= pc_reg + 32'h4;
                    end
                    //Both log statements shows same result
                    //$display("FETCH_DONE: PC=0x%x, IS=0x%x Opcode=%h, rd=%d, rs1=%d, rs2=%d, imm=%h, alu_result=%d", pc_reg, instruction_reg, opcode, rd, rs1, rs2, immediate, alu_result);
                end
                
                DECODE: begin
                    $display("DECODE_DONE: PC=0x%x, IS=0x%x Opcode=%h, rd=%d, rs1=%d, rs2=%d, imm=%h, alu_result=%d", pc_reg, instruction_reg, opcode, rd, rs1, rs2, immediate, alu_result);
                    // Decode happens combinatorially
                end
                
                EXECUTE: begin
                    $display("EXECUTE_BEGIN: PC=0x%x, IS=0x%x Opcode=%h, rd=%d, rs1=%d, rs2=%d, imm=%h, alu_result=%d", pc_reg, instruction_reg, opcode, rd, rs1, rs2, immediate, alu_result);
                    
                    // ------ BEGIN: Handle the result of ALU operations-----
                    alu_result_reg <= alu_result;
                    
                    // Update flags for ALU operations
                    if (opcode == ALU_ADD || opcode == ALU_SUB || opcode == ALU_AND || opcode == ALU_OR || 
                        opcode == ALU_XOR || opcode == ALU_NOT || opcode == ALU_SHL || opcode == ALU_SHR ||
                        opcode == ALU_MUL || opcode == ALU_DIV || opcode == ALU_MOD || opcode == ALU_CMP || opcode == ALU_SAR) begin
                        flags_reg <= flags_out;
                        $display("EXECUTE_DEBUG_ALU: Flags updated to C=%b Z=%b N=%b V=%b", 
                                flags_out[0], flags_out[1], flags_out[2], flags_out[3]);
                    end

                    // ------ END: Handle the result of ALU operations-----

                    // ------ BEGIN: Handle SET instructions -----
                    if (opcode == OP_SETEQ || opcode == OP_SETNE || opcode == OP_SETLT ||
                        opcode == OP_SETGE || opcode == OP_SETLE || opcode == OP_SETGT) begin
                        $display("SET MATCHED..");
                        $display("%h %h %h %h %h %h", opcode, OP_SETEQ, OP_SETNE, OP_SETLT, OP_SETGE, OP_SETLE, OP_SETGT);
                        $display("OP_SETEQ: %h", opcode==OP_SETEQ);
                        $display("OP_SETNE: %h", opcode==OP_SETNE);
                        $display("OP_SETLT: %h", opcode==OP_SETLT);
                        $display("OP_SETGE: %h", opcode==OP_SETGE);
                        $display("OP_SETLE: %h", opcode==OP_SETLE);
                        $display("OP_SETGT: %h", opcode==OP_SETGT);

                        case (opcode)
                            OP_SETEQ: alu_result_reg <= flags_reg[1] ? 32'h1 : 32'h0;  // Z flag
                            OP_SETNE: alu_result_reg <= !flags_reg[1] ? 32'h1 : 32'h0; // !Z flag
                            OP_SETLT: alu_result_reg <= flags_reg[2] ? 32'h1 : 32'h0;  // N flag
                            OP_SETGE: alu_result_reg <= !flags_reg[2] ? 32'h1 : 32'h0; // !N flag
                            OP_SETLE: alu_result_reg <= (flags_reg[2] || flags_reg[1]) ? 32'h1 : 32'h0; // N || Z
                            OP_SETGT: alu_result_reg <= (!flags_reg[2] && !flags_reg[1]) ? 32'h1 : 32'h0; // !N && !Z
                        endcase
                        $display("EXECUTE_DEBUG_SET1: Checking SET condition: opcode=%h, OP_SETEQ=%h, condition=%b", 
                            opcode, OP_SETEQ, (opcode == OP_SETEQ || opcode == OP_SETNE || opcode == OP_SETLT ||
                            opcode == OP_SETGE || opcode == OP_SETLE || opcode == OP_SETGT));

                        $display("EXECUTE_DEBUG_SET2: SET instruction - opcode=%h, flags=0x%h, result=%d", 
                                opcode, flags_reg, alu_result_reg);
                    end
                    // ------ END: Handle SET instructions -----


                    if (opcode == OP_HALT) begin // HALT
                        halted_reg <= 1'b1;
                    end
                    // Branch/jump PC update
                    if (is_branch_jump && branch_taken) begin
                        pc_reg <= pc_reg + ({{23{imm12[8]}}, imm12} << 2);
                        $display("DEBUG CPU: Branch taken from PC=0x%x to PC=0x%x, offset=%d", 
                                pc_reg, pc_reg + ({{23{imm12[8]}}, imm12} << 2), {{23{imm12[8]}}, imm12});
                    end else if (is_branch_jump && !branch_taken) begin
                        $display("DEBUG CPU: Branch not taken at PC=0x%x, condition failed", pc_reg);
                    end
                    // Debug output for ALU operations
                    // FIX ADDI
                    if (opcode == ALU_ADD || opcode == 6'h000000) begin // ADD/ADDI
                        $display("DEBUG ALU: ADD/ADDI - op=%s R%d = R%d + %s%d => %d", 
                                (opcode == 6'h04) ? "ADD" : "ADDI",
                                rd, rs1, 
                                (opcode == 6'h04) ? "R" : "#",
                                (opcode == 6'h04) ? rs2 : immediate,
                                alu_result);
                    end
                    // LOADI: Write immediate to register (no ALU)
                    if (opcode == MEM_LOADI) begin
                        alu_result_reg <= immediate;
                        $display("DEBUG CPU: LOADI R%d = 0x%h", rd, immediate);
                    end
                    $display("EXECUTE_DONE: PC=0x%x, IS=0x%x Opcode=%h, rd=%d, rs1=%d, rs2=%d, imm=%h", pc_reg, instruction_reg, opcode, rd, rs1, rs2, immediate);
                end
                
                MEMORY: begin
                    $display("STATE_MEMORY:");
                    if (is_load_store && opcode == MEM_LOAD) begin // LOAD
                        memory_data_reg <= data_bus;
                        $display("DEBUG CPU: LOAD from addr=0x%x, data=%d", immediate, data_bus);
                    end
                    if (opcode == MEM_STORE) begin // STORE
                        $display("DEBUG CPU: STORE R%d=%d to addr=0x%x, mem_write=%b, data_bus=0x%x", 
                                store_direct_addr ? rd : rs1, reg_data_a, immediate, mem_write, data_bus);
                    end
                end
                
                WRITEBACK: begin
                    $display("STATE_WRITEBACK:");
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
    assign is_immediate_inst = 1'b0; // (set as needed for your ISA)
    assign is_load_store = (opcode == MEM_LOAD) || (opcode == MEM_STORE);
    assign is_branch_jump = (opcode >= OP_JMP && opcode <= OP_POP);
    
    // Enhanced memory addressing intelligence
    wire is_log_buffer_access = (immediate >= 32'h3000) && (immediate < 32'h5000);
    wire is_stack_access = (immediate >= 32'h7000) && (immediate < 32'h8000);
    wire is_io_access = (immediate >= 32'h8000) && (immediate < 32'h9000);
    
    // Detect STORE with direct addressing (20-bit immediate format)
    // Format: opcode(6) | 000(2) | rs(4) | address(20)
    wire store_direct_addr = (opcode == MEM_STORE) && (instruction_reg[25:24] == 2'b00);
    
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
    assign immediate = (opcode == MEM_LOAD) ? {13'h0000, imm20} :                         // LOAD: 19-bit address
                      (opcode == MEM_STORE && store_direct_addr) ? {13'h0000, imm20} :     // STORE direct: 19-bit address  
                      (opcode == MEM_STORE && !store_direct_addr) ? {{23{imm12[8]}}, imm12} : // STORE reg+offset: 9-bit offset
                      (opcode == MEM_LOADI) ? {13'h0000, imm20} :                         // LOADI: 19-bit immediate
                      ((opcode == 6'h05) || (opcode == 6'h07)) ? {{23{imm12[8]}}, imm12} : // ADDI/SUBI: 9-bit signed
                      {{23{imm12[8]}}, imm12};                                             // Default: 9-bit signed
    
    // ALU connections
    assign alu_a = reg_data_a;
    assign alu_b = is_immediate_inst ? immediate : reg_data_b;
    assign alu_op = (opcode == ALU_ADD) ? ALU_ADD :
                   (opcode == ALU_SUB) ? ALU_SUB :
                   (opcode == ALU_AND) ? ALU_AND :
                   (opcode == ALU_OR)  ? ALU_OR  :
                   (opcode == ALU_XOR) ? ALU_XOR :
                   (opcode == ALU_NOT) ? ALU_NOT :
                   (opcode == ALU_SHL) ? ALU_SHL :
                   (opcode == ALU_SHR) ? ALU_SHR :
                   (opcode == ALU_MUL) ? ALU_MUL :
                   (opcode == ALU_DIV) ? ALU_DIV :
                   (opcode == ALU_MOD) ? ALU_MOD :
                   (opcode == ALU_CMP) ? ALU_CMP :
                   (opcode == ALU_SAR) ? ALU_SAR :
                   ALU_ADD; // Default ADD
    
    assign flags_in = flags_reg; // Use stored flags as input to ALU
    
    // Register file connections
    assign reg_addr_a = (opcode == MEM_STORE) ? rd : rs1;  // For STORE, source data is in rd; others use rs1
    assign reg_addr_b = (opcode == MEM_STORE && !store_direct_addr) ? rs1 : rs2;  // For STORE register addressing, address base is in rs1
    assign reg_addr_w = rd;   // Always use rd for write destination
    assign reg_data_w = (state == WRITEBACK) ? 
                       ((opcode == MEM_LOAD) ? memory_data_reg :
                        (opcode == MEM_LOADI) ? immediate :
                        alu_result_reg) : 32'h0;
    // DEBUG: Show what is being written to the register file
    always @(*) begin
        if (state == WRITEBACK) begin
            $display("DEBUG reg_data_w: state=WRITEBACK, reg_data_w=0x%h, opcode=0x%h, alu_result_reg=0x%h, memory_data_reg=0x%h, immediate=0x%h", reg_data_w, opcode, alu_result_reg, memory_data_reg, immediate);
        end
    end
    
    assign reg_write_en = (state == WRITEBACK) && 
                         !(opcode == MEM_STORE) && !(opcode == OP_HALT) && !is_branch_jump ||
                         (state == WRITEBACK) && (opcode == OP_SETEQ || opcode == OP_SETNE || 
                          opcode == OP_SETLT || opcode == OP_SETGE || opcode == OP_SETLE || opcode == OP_SETGT) ||
                         (state == WRITEBACK) && (opcode == MEM_LOADI);

                         

    // Memory interface with intelligent addressing
    assign addr_bus = (state == FETCH) ? pc_reg : 
                     (state == MEMORY && is_load_store && store_direct_addr) ? immediate :     // Direct addressing: use immediate as address
                     (state == MEMORY && is_load_store && !store_direct_addr) ? (reg_data_b + immediate) : // Register+offset: base + offset
                     (state == MEMORY && is_load_store) ? immediate :         // LOAD: always direct addressing
                     pc_reg;
    
    assign data_bus = (state == MEMORY && opcode == MEM_STORE && mem_write) ? reg_data_a : 32'hZZZZZZZZ;
    
    assign mem_read = (state == FETCH) ? 1'b1 : 
                     (state == MEMORY && opcode == MEM_LOAD) ? 1'b1 : 1'b0;
    
    assign mem_write = (state == MEMORY && opcode == MEM_STORE) ? 1'b1 : 1'b0;
    
    // Debug outputs
    always @(posedge clk) begin
        if (!rst_n) begin
            // Reset debug state
        end else begin
            //$display("DEBUG CPU State: state=%b, next_state=%b, opcode=0x%h, pc=0x%h, alu_result_reg=0x%h, reg_write_en=%b, reg_addr_w=%d, reg_data_w=0x%h", state, next_state, opcode, pc_reg, alu_result_reg, reg_write_en, reg_addr_w, reg_data_w);
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
    assign user_mode = user_mode_reg;
    assign cpu_flags = flags_reg;

endmodule
