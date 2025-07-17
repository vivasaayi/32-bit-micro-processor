package util;

import java.util.HashMap;
import java.util.Map;

/**
 * Shared instruction decoder for both Hex and SimulationLog tabs
 */
public class InstructionDecoder {
    
    private static final Map<Integer, String> OPCODE_MAP = new HashMap<>();
    
    static {
        // ALU operations (0x00–0x0F)
        OPCODE_MAP.put(0x00, "ADD");
        OPCODE_MAP.put(0x01, "SUB");
        OPCODE_MAP.put(0x02, "AND");
        OPCODE_MAP.put(0x03, "OR");
        OPCODE_MAP.put(0x04, "XOR");
        OPCODE_MAP.put(0x05, "NOT");
        OPCODE_MAP.put(0x06, "SHL");
        OPCODE_MAP.put(0x07, "SHR");
        OPCODE_MAP.put(0x08, "MUL");
        OPCODE_MAP.put(0x09, "DIV");
        OPCODE_MAP.put(0x0A, "MOD");
        OPCODE_MAP.put(0x0B, "CMP");
        OPCODE_MAP.put(0x0C, "SAR");
        OPCODE_MAP.put(0x0D, "ADDI");
        OPCODE_MAP.put(0x0E, "SUBI");
        OPCODE_MAP.put(0x0F, "CMPI");
        
        // Memory operations (0x10–0x12)
        OPCODE_MAP.put(0x10, "LOAD");
        OPCODE_MAP.put(0x11, "STORE");
        OPCODE_MAP.put(0x12, "LOADI");
        
        // Control/Branch opcodes (0x20–0x2B)
        OPCODE_MAP.put(0x20, "JMP");
        OPCODE_MAP.put(0x21, "JZ");
        OPCODE_MAP.put(0x22, "JNZ");
        OPCODE_MAP.put(0x23, "JC");
        OPCODE_MAP.put(0x24, "JNC");
        OPCODE_MAP.put(0x25, "JLT");
        OPCODE_MAP.put(0x26, "JGE");
        OPCODE_MAP.put(0x27, "JLE");
        OPCODE_MAP.put(0x28, "CALL");
        OPCODE_MAP.put(0x29, "RET");
        OPCODE_MAP.put(0x2A, "PUSH");
        OPCODE_MAP.put(0x2B, "POP");
        
        // Set/Compare opcodes (0x30–0x35)
        OPCODE_MAP.put(0x30, "SETEQ");
        OPCODE_MAP.put(0x31, "SETNE");
        OPCODE_MAP.put(0x32, "SETLT");
        OPCODE_MAP.put(0x33, "SETGE");
        OPCODE_MAP.put(0x34, "SETLE");
        OPCODE_MAP.put(0x35, "SETGT");
        
        // System/Privileged opcodes (0x3E–0x3F)
        OPCODE_MAP.put(0x3E, "HALT");
        OPCODE_MAP.put(0x3F, "OUT");
    }
    
    public static Object[] decodeInstruction(int address, int instruction) {
        int opcode = (instruction >>> 26) & 0x3F;  // [31:26]
        int rd = (instruction >>> 19) & 0x1F;      // [23:19] 
        int rs1 = (instruction >>> 14) & 0x1F;     // [18:14]
        int rs2 = (instruction >>> 9) & 0x1F;      // [13:9]
        
        // Handle different immediate field sizes based on instruction type
        int immediate;
        if (opcode == 0x12) { // LOADI uses 19-bit immediate [18:0]
            immediate = instruction & 0x7FFFF;
            // Sign extend 19-bit immediate
            if ((immediate & 0x40000) != 0) {
                immediate |= 0xFFF80000;
            }
        } else if (opcode >= 0x0D && opcode <= 0x0F) { // ADDI, SUBI, CMPI use 12-bit immediate [11:0]
            immediate = instruction & 0xFFF;
            // Sign extend 12-bit immediate
            if ((immediate & 0x800) != 0) {
                immediate |= 0xFFFFF000;
            }
        } else if (opcode >= 0x20 && opcode <= 0x2B) { // Branch/Jump instructions use 12-bit immediate [11:0]
            immediate = instruction & 0xFFF;
            // Sign extend 12-bit immediate
            if ((immediate & 0x800) != 0) {
                immediate |= 0xFFFFF000;
            }
        } else { // Default to 12-bit immediate [11:0]
            immediate = instruction & 0xFFF;
            // Sign extend 12-bit immediate
            if ((immediate & 0x800) != 0) {
                immediate |= 0xFFFFF000;
            }
        }
        
        String mnemonic = OPCODE_MAP.getOrDefault(opcode, "OP_" + String.format("%02X", opcode));
        String comment = generateComment(opcode, rd, rs1, rs2, immediate);
        
        return new Object[] {
            String.format("0x%08X", address),           // Address
            String.format("0x%02X", opcode),            // Opcode
            String.format("R%d", rd),                   // RD
            String.format("R%d", rs1),                  // RS1
            String.format("R%d", rs2),                  // RS2
            String.valueOf(immediate),                  // IMM
            mnemonic,                                   // Mnemonic
            comment                                     // Comment
        };
    }
    
    public static Object[] decodeFromSimLog(String pc, int opcode, int rd, int rs1, int rs2, int imm) {
        String mnemonic = OPCODE_MAP.getOrDefault(opcode, "OP_" + String.format("%02X", opcode));
        String comment = generateComment(opcode, rd, rs1, rs2, imm);
        
        return new Object[] {
            pc,                                         // PC
            String.format("0x%02X", opcode),            // OpCode
            mnemonic,                                   // Mnemonic
            String.format("R%d", rd),                   // RD
            String.format("R%d", rs1),                  // RS1
            String.format("R%d", rs2),                  // RS2
            String.valueOf(imm),                        // IMM
            comment                                     // Description
        };
    }
    
    private static String generateComment(int opcode, int rd, int rs1, int rs2, int imm) {
        String mnemonic = OPCODE_MAP.getOrDefault(opcode, "UNKNOWN");
        
        switch (mnemonic) {
            case "ADD":
                return String.format("R%d = R%d + R%d", rd, rs1, rs2);
            case "SUB":
                return String.format("R%d = R%d - R%d", rd, rs1, rs2);
            case "AND":
                return String.format("R%d = R%d & R%d", rd, rs1, rs2);
            case "OR":
                return String.format("R%d = R%d | R%d", rd, rs1, rs2);
            case "XOR":
                return String.format("R%d = R%d ^ R%d", rd, rs1, rs2);
            case "NOT":
                return String.format("R%d = ~R%d", rd, rs1);
            case "SHL":
                return String.format("R%d = R%d << R%d", rd, rs1, rs2);
            case "SHR":
                return String.format("R%d = R%d >> R%d", rd, rs1, rs2);
            case "SAR":
                return String.format("R%d = R%d >>> R%d", rd, rs1, rs2);
            case "MUL":
                return String.format("R%d = R%d * R%d", rd, rs1, rs2);
            case "DIV":
                return String.format("R%d = R%d / R%d", rd, rs1, rs2);
            case "MOD":
                return String.format("R%d = R%d %% R%d", rd, rs1, rs2);
            case "CMP":
                return String.format("Compare R%d with R%d", rs1, rs2);
            case "LOAD":
                return String.format("R%d = MEM[0x%X]", rd, imm);
            case "STORE":
                return String.format("MEM[0x%X] = R%d", imm, rd);
            case "LOADI":
                return String.format("R%d = 0x%X (immediate)", rd, imm & 0x7FFFF); // Mask to 19 bits for display
            case "JMP":
                return String.format("Jump to 0x%X", imm);
            case "JZ":
                return String.format("Jump to 0x%X if zero", imm);
            case "JNZ":
                return String.format("Jump to 0x%X if not zero", imm);
            case "JC":
                return String.format("Jump to 0x%X if carry", imm);
            case "JNC":
                return String.format("Jump to 0x%X if not carry", imm);
            case "JLT":
                return String.format("Jump to 0x%X if less than", imm);
            case "JGE":
                return String.format("Jump to 0x%X if greater/equal", imm);
            case "JLE":
                return String.format("Jump to 0x%X if less/equal", imm);
            case "CALL":
                return String.format("Call subroutine at 0x%X", imm);
            case "RET":
                return "Return from subroutine";
            case "PUSH":
                return String.format("Push R%d to stack", rd);
            case "POP":
                return String.format("Pop to R%d from stack", rd);
            case "SETEQ":
                return String.format("R%d = (R%d == R%d) ? 1 : 0", rd, rs1, rs2);
            case "SETNE":
                return String.format("R%d = (R%d != R%d) ? 1 : 0", rd, rs1, rs2);
            case "SETLT":
                return String.format("R%d = (R%d < R%d) ? 1 : 0", rd, rs1, rs2);
            case "SETGE":
                return String.format("R%d = (R%d >= R%d) ? 1 : 0", rd, rs1, rs2);
            case "SETLE":
                return String.format("R%d = (R%d <= R%d) ? 1 : 0", rd, rs1, rs2);
            case "SETGT":
                return String.format("R%d = (R%d > R%d) ? 1 : 0", rd, rs1, rs2);
            case "HALT":
                return "Stop execution";
            case "INT":
                return "Software interrupt";
            default:
                return String.format("Operation %s", mnemonic);
        }
    }
    
    public static String getOpcodeName(int opcode) {
        return OPCODE_MAP.getOrDefault(opcode, "OP_" + String.format("%02X", opcode));
    }
}
