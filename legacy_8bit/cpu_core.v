/**
 * 8-Bit Microprocessor CPU Core
 * 
 * This is the main CPU core that integrates all components:
 * - ALU for arithmetic and logic operations
 * - Register file for data storage
 * - Control unit for instruction decode
 * - Memory interface for data/instruction access
 * 
 * Features:
 * - 8-bit data bus, 16-bit address bus
 * - Von Neumann architecture
 * - Pipelined execution (Fetch, Decode, Execute)
 * - Interrupt handling
 * - User/Kernel mode support
 */

module cpu_core (
    input wire clk,
    input wire rst_n,
    
    // Memory interface
    output wire [15:0] addr_bus,
    inout wire [7:0] data_bus,
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

    // Internal buses and control signals
    wire [7:0] alu_a, alu_b, alu_result;
    wire [3:0] alu_op;
    wire [7:0] flags_in, flags_out;
    wire flags_we;
    
    // Register file signals
    wire [2:0] reg_addr_a, reg_addr_b, reg_addr_w;
    wire [7:0] reg_data_a, reg_data_b, reg_data_w;
    wire reg_write_en;
    
    // Special registers
    reg [15:0] pc;          // Program Counter
    reg [15:0] sp;          // Stack Pointer
    reg [7:0] flags;        // Status flags
    
    // Control unit signals
    wire [7:0] instruction;
    wire [3:0] opcode;
    wire [2:0] reg1, reg2;
    wire imm_flag;
    wire [15:0] immediate_addr;
    wire [7:0] immediate_data;
    
    // Pipeline registers
    reg [7:0] fetch_instruction;
    reg [15:0] fetch_pc;
    reg [7:0] decode_instruction;
    reg [15:0] decode_pc;
    
    // State machine states
    localparam FETCH = 3'b000;
    localparam DECODE = 3'b001;
    localparam EXECUTE = 3'b010;
    localparam MEMORY = 3'b011;
    localparam WRITEBACK = 3'b100;
    localparam INTERRUPT = 3'b101;
    localparam HALT = 3'b110;
    
    reg [2:0] cpu_state;
    reg [2:0] next_state;
    
    // Control signals
    wire pc_write_en;
    wire sp_write_en;
    reg [15:0] pc_next;
    reg [15:0] sp_next;
    wire halt_cpu;
    reg interrupt_enable;
    
    // Memory interface control
    reg [15:0] mem_addr;
    reg [7:0] mem_data_out;
    wire mem_read_req;
    wire mem_write_req;
    wire [7:0] mem_data_in;
    
    // Flag definitions
    localparam FLAG_CARRY     = 0;
    localparam FLAG_ZERO      = 1;
    localparam FLAG_NEGATIVE  = 2;
    localparam FLAG_OVERFLOW  = 3;
    localparam FLAG_INTERRUPT = 4;
    localparam FLAG_USER      = 5;
    
    // Assign outputs
    assign addr_bus = mem_addr;
    assign mem_read = mem_read_req;
    assign mem_write = mem_write_req;
    assign halted = (cpu_state == HALT);
    assign user_mode = flags[FLAG_USER];
    assign interrupt_ack = (cpu_state == INTERRUPT);
    
    // Tri-state data bus control
    assign data_bus = mem_write_req ? mem_data_out : 8'bZ;
    assign mem_data_in = data_bus;
    
    // Instruction decode
    assign opcode = decode_instruction[7:4];
    assign reg1 = decode_instruction[3:1];
    assign reg2 = decode_instruction[1:0];
    assign imm_flag = decode_instruction[0];
    
    // Instantiate ALU
    alu cpu_alu (
        .a(alu_a),
        .b(alu_b),
        .op(alu_op),
        .result(alu_result),
        .flags_in(flags),
        .flags_out(flags_out)
    );
    
    // Instantiate Register File
    register_file cpu_registers (
        .clk(clk),
        .rst_n(rst_n),
        .addr_a(reg_addr_a),
        .addr_b(reg_addr_b),
        .addr_w(reg_addr_w),
        .data_a(reg_data_a),
        .data_b(reg_data_b),
        .data_w(reg_data_w),
        .write_en(reg_write_en)
    );
    
    // Instantiate Control Unit
    control_unit cpu_control (
        .clk(clk),
        .rst_n(rst_n),
        .instruction(decode_instruction),
        .flags(flags),
        .state(cpu_state),
        .alu_op(alu_op),
        .reg_addr_a(reg_addr_a),
        .reg_addr_b(reg_addr_b),
        .reg_addr_w(reg_addr_w),
        .reg_write_en(reg_write_en),
        .mem_read_en(),        // Not connected for now
        .mem_write_en(),       // Not connected for now
        .pc_write_en(pc_write_en),
        .sp_write_en(sp_write_en),
        .flags_we(flags_we),
        .halt_cpu(halt_cpu)
    );
    
    // Main CPU state machine
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cpu_state <= FETCH;
            pc <= 16'h8000;  // Start at kernel space
            sp <= 16'h7FFF;  // Stack starts at end of user space
            flags <= 8'h00;
            interrupt_enable <= 1'b0;
            fetch_instruction <= 8'h00;
            decode_instruction <= 8'h00;
        end else begin
            cpu_state <= next_state;
            
            // Update special registers
            if (pc_write_en) pc <= pc_next;
            if (sp_write_en) sp <= sp_next;
            if (flags_we) flags <= flags_out;
            
            // Pipeline stages
            case (cpu_state)
                FETCH: begin
                    fetch_instruction <= mem_data_in;
                    fetch_pc <= pc;
                end
                
                DECODE: begin
                    decode_instruction <= fetch_instruction;
                    decode_pc <= fetch_pc;
                end
            endcase
        end
    end
    
    // State machine next state logic
    always @(*) begin
        next_state = cpu_state;
        mem_addr = 16'h0000;
        mem_data_out = 8'h00;
        pc_next = pc;
        sp_next = sp;
        
        case (cpu_state)
            FETCH: begin
                mem_addr = pc;
                if (mem_ready) begin
                    next_state = DECODE;
                    pc_next = pc + 1;
                end
            end
            
            DECODE: begin
                next_state = EXECUTE;
            end
            
            EXECUTE: begin
                // Execute instruction based on opcode
                case (opcode)
                    4'h0, 4'h1, 4'h2, 4'h3, 4'h4, 4'h5: begin // Arithmetic
                        next_state = WRITEBACK;
                    end
                    
                    4'h3: begin // Memory operations
                        next_state = MEMORY;
                    end
                    
                    4'h4, 4'h5: begin // Branches and calls
                        next_state = FETCH;
                        // Branch logic handled in control unit
                    end
                    
                    4'h6: begin // System instructions
                        if (decode_instruction == 8'h64) begin // HALT
                            next_state = HALT;
                        end else begin
                            next_state = WRITEBACK;
                        end
                    end
                    
                    default: begin
                        next_state = WRITEBACK;
                    end
                endcase
            end
            
            MEMORY: begin
                if (mem_ready) begin
                    next_state = WRITEBACK;
                end
            end
            
            WRITEBACK: begin
                next_state = FETCH;
            end
            
            INTERRUPT: begin
                // Handle interrupt
                next_state = FETCH;
            end
            
            HALT: begin
                // Stay halted until reset
                next_state = HALT;
            end
        endcase
        
        // Interrupt handling
        if (|interrupt_req && flags[FLAG_INTERRUPT] && (cpu_state != INTERRUPT)) begin
            next_state = INTERRUPT;
        end
    end
    
    // Memory request generation
    assign mem_read_req = (cpu_state == FETCH);
    assign mem_write_req = 1'b0; // Simplified for now
    
    // ALU input multiplexers
    reg [7:0] alu_a_reg, alu_b_reg;
    assign alu_a = alu_a_reg;
    assign alu_b = alu_b_reg;
    
    // ALU input selection
    always @(*) begin
        alu_a_reg = reg_data_a;
        
        case (opcode[3:0])
            4'h4, 4'h5: begin // Immediate arithmetic
                alu_b_reg = immediate_data;
            end
            default: begin
                alu_b_reg = reg_data_b;
            end
        endcase
    end
    
endmodule
