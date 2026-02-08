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
 * | 0x33   | 0x3    | 0x00   | SLTU             |
 * | 0x33   | 0x4    | 0x00   | XOR              |
 * | 0x33   | 0x5    | 0x00   | SRL              |
 * | 0x33   | 0x5    | 0x20   | SRA              |
 * | 0x33   | 0x6    | 0x00   | OR               |
 * | 0x33   | 0x7    | 0x00   | AND              |
 * | 0x13   | 0x0    | -      | ADDI             |
 * | 0x13   | 0x1    | 0x00   | SLLI             |
 * | 0x13   | 0x2    | -      | SLTI             |
 * | 0x13   | 0x3    | -      | SLTIU            |
 * | 0x13   | 0x4    | -      | XORI             |
 * | 0x13   | 0x5    | 0x00   | SRLI             |
 * | 0x13   | 0x5    | 0x20   | SRAI             |
 * | 0x13   | 0x6    | -      | ORI              |
 * | 0x13   | 0x7    | -      | ANDI             |
 * ---------------------------------------------------
 */

module alu (
    input wire [31:0] a,         // First operand (rs1 value or PC)
    input wire [31:0] b,         // Second operand (rs2 value or immediate)
    input wire [6:0] opcode,     // RISC-V opcode (7-bit)
    input wire [2:0] funct3,     // RISC-V funct3 (3-bit)
    input wire [6:0] funct7,     // RISC-V funct7 (7-bit)
    output reg [31:0] result     // ALU result (32-bit)
);

    // RISC-V Opcodes
    localparam OP_IMM   = 7'h13;
    localparam OP_REG   = 7'h33;
    localparam OP_LUI   = 7'h37;
    localparam OP_AUIPC = 7'h17;
    localparam OP_LOAD  = 7'h03;
    localparam OP_STORE = 7'h23;
    localparam OP_JALR  = 7'h67;
    
    always @(*) begin
        result = 32'h0;

        case (opcode)
            OP_REG: begin
                if (funct7 == 7'h01) begin // RV32M extension
                    case (funct3)
                        3'h0: result = a * b;                                               // MUL
                        3'h4: result = (b != 0) ? $signed(a) / $signed(b) : 32'hFFFFFFFF;   // DIV
                        3'h5: result = (b != 0) ? a / b : 32'hFFFFFFFF;                      // DIVU
                        3'h6: result = (b != 0) ? $signed(a) % $signed(b) : a;               // REM
                        3'h7: result = (b != 0) ? a % b : a;                                 // REMU
                        default: result = 32'h0;
                    endcase
                end else begin // RV32I
                    case (funct3)
                        3'h0: result = (funct7 == 7'h20) ? (a - b) : (a + b); // ADD / SUB
                        3'h1: result = a << b[4:0];                             // SLL
                        3'h2: result = ($signed(a) < $signed(b)) ? 32'h1 : 32'h0; // SLT
                        3'h3: result = (a < b) ? 32'h1 : 32'h0;                // SLTU
                        3'h4: result = a ^ b;                                   // XOR
                        3'h5: begin // SRL / SRA
                            if (funct7 == 7'h20)
                                result = $signed(a) >>> b[4:0]; // SRA
                            else
                                result = a >> b[4:0];           // SRL
                        end
                        3'h6: result = a | b;                                   // OR
                        3'h7: result = a & b;                                   // AND
                        default: result = 32'h0;
                    endcase
                end
            end
            OP_IMM: begin
                case (funct3)
                    3'h0: result = a + b;                                               // ADDI
                    3'h1: result = a << b[4:0];                                         // SLLI
                    3'h2: result = ($signed(a) < $signed(b)) ? 32'h1 : 32'h0;           // SLTI
                    3'h3: result = (a < b) ? 32'h1 : 32'h0;                             // SLTIU
                    3'h4: result = a ^ b;                                                // XORI
                    3'h5: begin // SRLI / SRAI
                        if (funct7 == 7'h20)
                            result = $signed(a) >>> b[4:0]; // SRAI
                        else
                            result = a >> b[4:0];           // SRLI
                    end
                    3'h6: result = a | b;                                                // ORI
                    3'h7: result = a & b;                                                // ANDI
                    default: result = 32'h0;
                endcase
            end
            OP_LUI:                     result = b;     // LUI (immediate already shifted)
            OP_AUIPC:                   result = a + b; // PC + upper immediate
            OP_LOAD, OP_STORE, OP_JALR: result = a + b; // Address calculation
            default:                    result = 32'h0;
        endcase
    end

endmodule
