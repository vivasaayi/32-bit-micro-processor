/**
 * 32-Bit ALU (Arithmetic Logic Unit)
 * 
 * Performs arithmetic and logic operations for the 32-bit microprocessor.
 * Supports all basic operations needed for a functional processor.
 *
 * ALU OPCODE TABLE (RV32I/M compatible)
 * 
 * R-TYPE (0x33 - Register-Register operations):
 * | funct3 | funct7 | Operation         |
 * |--------|--------|------------------|
 * | 0x0    | 0x00   | ADD              |
 * | 0x0    | 0x20   | SUB              |
 * | 0x1    | 0x00   | SLL              |
 * | 0x2    | 0x00   | SLT              |
 * | 0x3    | 0x00   | SLTU             |
 * | 0x4    | 0x00   | XOR              |
 * | 0x5    | 0x00   | SRL              |
 * | 0x5    | 0x20   | SRA              |
 * | 0x6    | 0x00   | OR               |
 * | 0x7    | 0x00   | AND              |
 * | 0x0    | 0x01   | MUL (RV32M)      |
 * | 0x1    | 0x01   | MULH (RV32M)     |
 * | 0x2    | 0x01   | MULHSU (RV32M)   |
 * | 0x3    | 0x01   | MULHU (RV32M)    |
 * | 0x4    | 0x01   | DIV (RV32M)      |
 * | 0x5    | 0x01   | DIVU (RV32M)     |
 * | 0x6    | 0x01   | REM (RV32M)      |
 * | 0x7    | 0x01   | REMU (RV32M)     |
 * 
 * I-TYPE (0x13 - Immediate operations):
 * | funct3 | funct7 | Operation         |
 * |--------|--------|------------------|
 * | 0x0    | -      | ADDI             |
 * | 0x1    | 0x00   | SLLI             |
 * | 0x2    | -      | SLTI             |
 * | 0x3    | -      | SLTIU            |
 * | 0x4    | -      | XORI             |
 * | 0x5    | 0x00   | SRLI             |
 * | 0x5    | 0x20   | SRAI             |
 * | 0x6    | -      | ORI              |
 * | 0x7    | -      | ANDI             |
 * 
 * Address Calculations (0x03, 0x23, 0x67):
 * | Opcode | Operation         |
 * |--------|------------------|
 * | 0x03   | LOAD address      |
 * | 0x23   | STORE address     |
 * | 0x67   | JALR address      |
 * 
 * U-TYPE (0x37, 0x17 - Upper immediate):
 * | Opcode | Operation         |
 * |--------|------------------|
 * | 0x37   | LUI              |
 * | 0x17   | AUIPC            |
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
    // R-TYPE (Register-Register operations)
    localparam OP_REG   = 7'h33;

    // I-TYPE (Immediate operations, loads, JALR)
    localparam OP_IMM   = 7'h13;
    localparam OP_LOAD  = 7'h03;
    localparam OP_JALR  = 7'h67;
    
    // S-TYPE (Store operations)
    localparam OP_STORE = 7'h23;
    
    // U-TYPE (Upper immediate operations)
    localparam OP_LUI   = 7'h37;
    localparam OP_AUIPC = 7'h17;
    
    reg [63:0] mul_res;
    
    always @(*) begin
        result = 32'h0;
        mul_res = 64'h0;

        case (opcode)
            OP_REG: begin
                if (funct7 == 7'h01) begin // RV32M extension
                    case (funct3)
                        3'h0: result = a * b;                                               // MUL: rd = (rs1 * rs2)[31:0]
                        3'h1: begin
                            mul_res = $signed(a) * $signed(b);                              // MULH: signed x signed
                            result = mul_res[63:32];
                        end
                        3'h2: begin
                            mul_res = $signed(a) * $signed({1'b0, b});                      // MULHSU: signed x unsigned
                            result = mul_res[63:32];
                        end
                        3'h3: begin
                            mul_res = a * b;                                                // MULHU: unsigned x unsigned
                            result = mul_res[63:32];
                        end
                        3'h4: begin // DIV: rd = rs1 / rs2
                            if (b == 0) 
                                result = 32'hFFFFFFFF; // DIV by zero
                            else if (a == 32'h80000000 && b == 32'hFFFFFFFF) 
                                result = 32'h80000000; // Overflow: INT_MIN / -1
                            else 
                                result = $signed(a) / $signed(b);
                        end
                        3'h5: result = (b != 0) ? a / b : 32'hFFFFFFFF;                      // DIVU
                        3'h6: begin // REM: rd = rs1 % rs2
                            if (b == 0) 
                                result = a;            // REM by zero
                            else if (a == 32'h80000000 && b == 32'hFFFFFFFF) 
                                result = 32'h0;        // Overflow: INT_MIN % -1
                            else 
                                result = $signed(a) % $signed(b);
                        end
                        3'h7: result = (b != 0) ? a % b : a;                                 // REMU
                        default: result = 32'h0;
                    endcase
                end else begin // RV32I
                    case (funct3)
                        3'h0: result = (funct7 == 7'h20) ? (a - b) : (a + b); // ADD / SUB
                        3'h1: result = a << b[4:0];                             // SLL: rd = rs1 << rs2[4:0]
                        3'h2: result = ($signed(a) < $signed(b)) ? 32'h1 : 32'h0; // SLT
                        3'h3: result = (a < b) ? 32'h1 : 32'h0;                // SLTU
                        3'h4: result = a ^ b;                                   // XOR
                        3'h5: begin // SRL / SRA
                            if (funct7 == 7'h20)
                                result = $signed(a) >>> b[4:0]; // SRA: arithmetic right shift
                            else
                                result = a >> b[4:0];           // SRL: logical right shift
                        end
                        3'h6: result = a | b;                                   // OR
                        3'h7: result = a & b;                                   // AND
                        default: result = 32'h0;
                    endcase
                end
            end
            OP_IMM: begin
                // RISC-V I-type immediate operations
                // Immediate is sign-extended 12-bit value, arithmetic overflow ignored
                // Shift amount in imm[4:0], shift type in funct7[5] (bit 30)
                case (funct3)
                    3'h0: result = a + b;                                               // ADDI: rd = rs1 + imm
                    3'h1: result = a << b[4:0];                                         // SLLI: rd = rs1 << imm[4:0]
                    3'h2: result = ($signed(a) < $signed(b)) ? 32'h1 : 32'h0;           // SLTI: rd = (rs1 < imm) ? 1 : 0 (signed)
                    3'h3: result = (a < b) ? 32'h1 : 32'h0;                             // SLTIU: rd = (rs1 < imm) ? 1 : 0 (unsigned)
                    3'h4: result = a ^ b;                                                // XORI: rd = rs1 ^ imm
                    3'h5: begin // SRLI / SRAI
                        if (funct7 == 7'h20)
                            result = $signed(a) >>> b[4:0]; // SRAI: arithmetic right shift (bit 30=1)
                        else
                            result = a >> b[4:0];           // SRLI: logical right shift (bit 30=0)
                    end
                    3'h6: result = a | b;                                                // ORI: rd = rs1 | imm
                    3'h7: result = a & b;                                                // ANDI: rd = rs1 & imm
                    default: result = 32'h0;
                endcase
            end
            OP_LUI:                     result = b;     // LUI: rd = U-imm << 12 (pre-shifted)
            OP_AUIPC:                   result = a + b; // AUIPC: rd = PC + (U-imm << 12) (pre-shifted)
            OP_LOAD, OP_STORE, OP_JALR: result = a + b; // Address calculation (rs1 + imm)
            default:                    result = 32'h0;
        endcase
    end

endmodule
