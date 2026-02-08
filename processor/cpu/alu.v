/**
 * 32-Bit ALU (Arithmetic Logic Unit)
 * 
 * Performs arithmetic and logic operations for the 32-bit microprocessor.
 * Supports all basic operations needed for a functional processor.
 *
 * ALU OPCODE TABLE (RV32I/M compatible)
 * | Opcode | funct3 | funct7 | Operation         |
 * |--------|--------|--------|------------------|
 * | 0x33   | 0x0    | 0x00   | ADD              |
 * | 0x33   | 0x0    | 0x20   | SUB              |
 * | 0x33   | 0x1    | 0x00   | SLL              |
 * | 0x33   | 0x2    | 0x00   | SLT              |
 * | 0x33   | 0x4    | 0x00   | XOR              |
 * | 0x33   | 0x5    | 0x00   | SRL              |
 * | 0x33   | 0x5    | 0x20   | SRA              |
 * | 0x33   | 0x6    | 0x00   | OR               |
 * | 0x33   | 0x7    | 0x00   | AND              |
 * | 0x13   | 0x0    | -      | ADDI             |
 * ---------------------------------------------------
 */

module alu (
    input wire [31:0] a,         // First operand (32-bit)
    input wire [31:0] b,         // Second operand (32-bit)
    input wire [6:0] opcode,     // RISC-V Opcode (7-bit)
    input wire [2:0] funct3,     // RISC-V funct3 (3-bit)
    input wire [6:0] funct7,     // RISC-V funct7 (7-bit)
    input wire [7:0] flags_in,   // Input flags (8-bit)
    output reg [31:0] result,    // Result (32-bit)
    output reg [7:0] flags_out   // Output flags (8-bit)
);

    // RISC-V Opcodes
    localparam OP_IMM   = 7'h13;
    localparam OP_REG   = 7'h33;
    localparam OP_LUI   = 7'h37;
    localparam OP_AUIPC = 7'h17;
    localparam OP_M     = 7'h33; // funct7=0x01 for RV32M
    localparam OP_LOAD  = 7'h03;
    localparam OP_STORE = 7'h23;
    localparam OP_JALR  = 7'h67;

    // Flag bit positions
    localparam FLAG_CARRY     = 0;
    localparam FLAG_ZERO      = 1;
    localparam FLAG_NEGATIVE  = 2;
    localparam FLAG_OVERFLOW  = 3;
    
    // Internal signals for proper arithmetic
    reg [32:0] temp_result;  // 33-bit for carry detection
    reg carry_in;
    reg [31:0] operand_a;
    reg [31:0] operand_b;
    
    // Debug signals
    reg [5:0] debug_op;
    
    always @(*) begin
        // Initialize
        operand_a = a;
        operand_b = b;
        temp_result = 33'h0;
        flags_out = flags_in;
        carry_in = flags_in[FLAG_CARRY];
        
        case (opcode)
            OP_REG: begin
                if (funct7 == 7'h01) begin // RV32M
                    case (funct3)
                        3'h0: begin // MUL
                            result = operand_a * operand_b;
                        end
                        3'h4: begin // DIV
                            if (operand_b != 0) result = $signed(operand_a) / $signed(operand_b);
                            else result = 32'hFFFFFFFF;
                        end
                        3'h6: begin // REM
                            if (operand_b != 0) result = $signed(operand_a) % $signed(operand_b);
                            else result = operand_a;
                        end
                        default: result = 32'h0;
                    endcase
                end else begin // RV32I
                    case (funct3)
                        3'h0: begin // ADD / SUB
                            if (funct7 == 7'h20) begin // SUB
                                temp_result = {1'b0, operand_a} - {1'b0, operand_b};
                                result = temp_result[31:0];
                                flags_out[FLAG_CARRY] = temp_result[32];
                            end else begin // ADD
                                temp_result = {1'b0, operand_a} + {1'b0, operand_b};
                                result = temp_result[31:0];
                                flags_out[FLAG_CARRY] = temp_result[32];
                            end
                        end
                        3'h1: result = operand_a << operand_b[4:0]; // SLL
                        3'h2: result = ($signed(operand_a) < $signed(operand_b)) ? 32'h1 : 32'h0; // SLT
                        3'h3: result = (operand_a < operand_b) ? 32'h1 : 32'h0; // SLTU
                        3'h4: result = operand_a ^ operand_b; // XOR
                        3'h5: begin // SRL / SRA
                            if (funct7 == 7'h20) result = $signed(operand_a) >>> operand_b[4:0]; // SRA
                            else result = operand_a >> operand_b[4:0]; // SRL
                        end
                        3'h6: result = operand_a | operand_b; // OR
                        3'h7: result = operand_a & operand_b; // AND
                        default: result = 32'h0;
                    endcase
                end
            end
            OP_IMM: begin
                case (funct3)
                    3'h0: result = operand_a + operand_b; // ADDI
                    3'h1: result = operand_a << operand_b[4:0]; // SLLI
                    3'h2: result = ($signed(operand_a) < $signed(operand_b)) ? 32'h1 : 32'h0; // SLTI
                    3'h3: result = (operand_a < operand_b) ? 32'h1 : 32'h0; // SLTIU
                    3'h4: result = operand_a ^ operand_b; // XORI
                    3'h5: begin // SRLI / SRAI
                        if (funct7 == 7'h20) result = $signed(operand_a) >>> operand_b[4:0]; // SRAI
                        else result = operand_a >> operand_b[4:0]; // SRLI
                    end
                    3'h6: result = operand_a | operand_b; // ORI
                    3'h7: result = operand_a & operand_b; // ANDI
                    default: result = 32'h0;
                endcase
            end
            OP_LUI: result = operand_b; // LUI (immediate already shifted in decoder)
            OP_AUIPC: result = operand_a + operand_b; // PC + immediate
            OP_LOAD, OP_STORE, OP_JALR: result = operand_a + operand_b; // Address calculation
            default: begin
                result = 32'h0;
                flags_out[FLAG_CARRY] = 1'b0;
            end
        endcase
        
        // Update other flags
        flags_out[FLAG_ZERO] = (result == 32'h0);
        flags_out[FLAG_NEGATIVE] = result[31];
    end

endmodule
