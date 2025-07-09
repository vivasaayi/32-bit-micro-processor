package util;

import java.util.HashMap;
import java.util.Map;

/**
 * Shared instruction decoder for both Hex and SimulationLog tabs
 */
public class InstructionDecoder {
    
    private static final Map<Integer, String> OPCODE_MAP = new HashMap<>();
    
    static {
        // ALU operations (0x00–0x1F)
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
        
        // Memory operations (0x20–0x2F)
        OPCODE_MAP.put(0x20, "LOAD");
        OPCODE_MAP.put(0x21, "STORE");
        OPCODE_MAP.put(0x22, "LOADI");
        
        // Control/Branch opcodes (0x30–0x3F)
        OPCODE_MAP.put(0x30, "JMP");
        OPCODE_MAP.put(0x31, "JZ");
        OPCODE_MAP.put(0x32, "JNZ");
        OPCODE_MAP.put(0x33, "JC");
        OPCODE_MAP.put(0x34, "JNC");
        OPCODE_MAP.put(0x35, "JLT");
        OPCODE_MAP.put(0x36, "JGE");
        OPCODE_MAP.put(0x37, "JLE");
        OPCODE_MAP.put(0x38, "CALL");
        OPCODE_MAP.put(0x39, "RET");
        OPCODE_MAP.put(0x3A, "PUSH");
        OPCODE_MAP.put(0x3B, "POP");
        
        // Set/Compare opcodes (0x40–0x4F)
        OPCODE_MAP.put(0x40, "SETEQ");
        OPCODE_MAP.put(0x41, "SETNE");
        OPCODE_MAP.put(0x42, "SETLT");
        OPCODE_MAP.put(0x43, "SETGE");
        OPCODE_MAP.put(0x44, "SETLE");
        OPCODE_MAP.put(0x45, "SETGT");
        
        // System/Privileged opcodes (0x50–0x5F)
        OPCODE_MAP.put(0x50, "HALT");
        OPCODE_MAP.put(0x51, "INT");
    }
    
    public static Object[] decodeInstruction(int address, int instruction) {
        int opcode = (instruction >>> 26) & 0x3F;  // [31:26]
        int rd = (instruction >>> 19) & 0x1F;      // [23:19] 
        int rs1 = (instruction >>> 14) & 0x1F;     // [18:14]
        int rs2 = (instruction >>> 9) & 0x1F;      // [13:9]
        int immediate = instruction & 0x1FF;       // [8:0]
        
        // Sign extend immediate
        if ((immediate & 0x100) != 0) {
            immediate |= 0xFFFFFE00;
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
                return String.format("R%d = 0x%X (immediate)", rd, imm);
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
