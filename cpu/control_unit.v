/**
 * Control Unit
 * 
 * Decodes instructions and generates control signals for the CPU.
 * Handles instruction sequencing, branching, and system calls.
 * 
 * Features:
 * - Instruction decode for all ISA instructions
 * - Control signal generation
 * - Branch condition evaluation
 * - System call handling
 */

module control_unit (
    input wire clk,
    input wire rst_n,
    input wire [7:0] instruction,
    input wire [7:0] flags,
    input wire [2:0] state,
    
    // ALU control
    output reg [3:0] alu_op,
    
    // Register file control
    output reg [2:0] reg_addr_a,
    output reg [2:0] reg_addr_b,
    output reg [2:0] reg_addr_w,
    output reg reg_write_en,
    
    // Memory control
    output reg mem_read_en,
    output reg mem_write_en,
    
    // Special register control
    output reg pc_write_en,
    output reg sp_write_en,
    output reg flags_we,
    
    // System control
    output reg halt_cpu
);

    // Instruction fields
    wire [3:0] opcode;
    wire [2:0] reg1, reg2;
    wire imm_flag;
    
    // State definitions
    localparam FETCH     = 3'b000;
    localparam DECODE    = 3'b001;
    localparam EXECUTE   = 3'b010;
    localparam MEMORY    = 3'b011;
    localparam WRITEBACK = 3'b100;
    localparam INTERRUPT = 3'b101;
    localparam HALT      = 3'b110;
    
    // Flag definitions
    localparam FLAG_CARRY     = 0;
    localparam FLAG_ZERO      = 1;
    localparam FLAG_NEGATIVE  = 2;
    localparam FLAG_OVERFLOW  = 3;
    localparam FLAG_INTERRUPT = 4;
    localparam FLAG_USER      = 5;
    
    // ALU operation codes
    localparam ALU_ADD  = 4'h0;
    localparam ALU_SUB  = 4'h1;
    localparam ALU_ADC  = 4'h2;
    localparam ALU_SBC  = 4'h3;
    localparam ALU_AND  = 4'h4;
    localparam ALU_OR   = 4'h5;
    localparam ALU_XOR  = 4'h6;
    localparam ALU_NOT  = 4'h7;
    localparam ALU_SHL  = 4'h8;
    localparam ALU_SHR  = 4'h9;
    localparam ALU_ROL  = 4'hA;
    localparam ALU_ROR  = 4'hB;
    localparam ALU_CMP  = 4'hC;
    localparam ALU_PASS = 4'hD;
    
    // Decode instruction fields
    assign opcode = instruction[7:4];
    assign reg1 = instruction[3:1];
    assign reg2 = instruction[1:0];
    assign imm_flag = instruction[0];
    
    // Main control logic
    always @(*) begin
        // Default values
        alu_op = ALU_PASS;
        reg_addr_a = 3'b000;
        reg_addr_b = 3'b000;
        reg_addr_w = 3'b000;
        reg_write_en = 1'b0;
        mem_read_en = 1'b0;
        mem_write_en = 1'b0;
        pc_write_en = 1'b0;
        sp_write_en = 1'b0;
        flags_we = 1'b0;
        halt_cpu = 1'b0;
        
        if (state == EXECUTE) begin
            case (opcode)
                // Arithmetic operations (0x0X)
                4'h0: begin // ADD/ADDI
                    alu_op = ALU_ADD;
                    reg_addr_a = reg1;
                    reg_addr_b = reg2;
                    reg_addr_w = reg1;
                    reg_write_en = 1'b1;
                    flags_we = 1'b1;
                end
                
                4'h1: begin // SUB/SUBI  
                    case (instruction[1:0])
                        2'b00: alu_op = ALU_SUB;
                        2'b01: alu_op = ALU_SUB;
                        2'b10: alu_op = ALU_ADC;
                        2'b11: alu_op = ALU_SBC;
                    endcase
                    reg_addr_a = reg1;
                    reg_addr_b = reg2;
                    reg_addr_w = reg1;
                    reg_write_en = 1'b1;
                    flags_we = 1'b1;
                end
                
                // Logic operations (0x1X)
                4'h2: begin
                    case (instruction[1:0])
                        2'b00: alu_op = ALU_AND;
                        2'b01: alu_op = ALU_OR;
                        2'b10: alu_op = ALU_XOR;
                        2'b11: alu_op = ALU_NOT;
                    endcase
                    reg_addr_a = reg1;
                    reg_addr_b = reg2;
                    reg_addr_w = reg1;
                    reg_write_en = 1'b1;
                    flags_we = 1'b1;
                end
                
                // Shift operations (0x2X)
                4'h3: begin
                    case (instruction[1:0])
                        2'b00: alu_op = ALU_SHL;
                        2'b01: alu_op = ALU_SHR;
                        2'b10: alu_op = ALU_ROL;
                        2'b11: alu_op = ALU_ROR;
                    endcase
                    reg_addr_a = reg1;
                    reg_addr_w = reg1;
                    reg_write_en = 1'b1;
                    flags_we = 1'b1;
                end
                
                // Memory operations (0x3X)
                4'h4: begin
                    case (instruction[1:0])
                        2'b00: begin // LOAD
                            mem_read_en = 1'b1;
                            reg_addr_w = reg1;
                            reg_write_en = 1'b1;
                        end
                        2'b01: begin // STORE
                            mem_write_en = 1'b1;
                            reg_addr_a = reg1;
                        end
                        2'b10: begin // LOADI
                            reg_addr_w = reg1;
                            reg_write_en = 1'b1;
                        end
                        2'b11: begin // LOADR/STORER
                            if (instruction[0]) begin // STORER
                                mem_write_en = 1'b1;
                                reg_addr_a = reg1;
                                reg_addr_b = reg2;
                            end else begin // LOADR
                                mem_read_en = 1'b1;
                                reg_addr_a = reg2;
                                reg_addr_w = reg1;
                                reg_write_en = 1'b1;
                            end
                        end
                    endcase
                end
                
                // Branch operations (0x4X)
                4'h5: begin
                    case (instruction[2:0])
                        3'b000: begin // JMP
                            pc_write_en = 1'b1;
                        end
                        3'b001: begin // JEQ
                            if (flags[FLAG_ZERO])
                                pc_write_en = 1'b1;
                        end
                        3'b010: begin // JNE
                            if (!flags[FLAG_ZERO])
                                pc_write_en = 1'b1;
                        end
                        3'b011: begin // JLT
                            if (flags[FLAG_NEGATIVE])
                                pc_write_en = 1'b1;
                        end
                        3'b100: begin // JGE
                            if (!flags[FLAG_NEGATIVE])
                                pc_write_en = 1'b1;
                        end
                        3'b101: begin // JCS
                            if (flags[FLAG_CARRY])
                                pc_write_en = 1'b1;
                        end
                        3'b110: begin // JCC
                            if (!flags[FLAG_CARRY])
                                pc_write_en = 1'b1;
                        end
                    endcase
                end
                
                // Subroutine operations (0x5X)
                4'h6: begin
                    case (instruction[1:0])
                        2'b00: begin // CALL
                            // Push PC to stack and jump
                            pc_write_en = 1'b1;
                            sp_write_en = 1'b1;
                            mem_write_en = 1'b1;
                        end
                        2'b01: begin // RET
                            // Pop PC from stack
                            pc_write_en = 1'b1;
                            sp_write_en = 1'b1;
                            mem_read_en = 1'b1;
                        end
                        2'b10: begin // PUSH
                            sp_write_en = 1'b1;
                            mem_write_en = 1'b1;
                            reg_addr_a = reg1;
                        end
                        2'b11: begin // POP
                            sp_write_en = 1'b1;
                            mem_read_en = 1'b1;
                            reg_addr_w = reg1;
                            reg_write_en = 1'b1;
                        end
                    endcase
                end
                
                // System operations (0x6X)
                4'h7: begin
                    case (instruction)
                        8'h60: begin // SYSCALL
                            // System call handling
                            // Implementation depends on OS
                        end
                        8'h61: begin // IRET
                            // Return from interrupt
                            pc_write_en = 1'b1;
                            flags_we = 1'b1;
                        end
                        8'h62: begin // EI
                            // Enable interrupts
                            flags_we = 1'b1;
                        end
                        8'h63: begin // DI
                            // Disable interrupts  
                            flags_we = 1'b1;
                        end
                        8'h64: begin // HALT
                            halt_cpu = 1'b1;
                        end
                        8'h65: begin // NOP
                            // No operation
                        end
                    endcase
                end
                
                // Compare operations (0x8X)
                4'h8: begin
                    alu_op = ALU_CMP;
                    reg_addr_a = reg1;
                    reg_addr_b = reg2;
                    flags_we = 1'b1;
                end
                
                default: begin
                    // Unknown instruction - treat as NOP
                end
            endcase
        end
    end
    
endmodule
