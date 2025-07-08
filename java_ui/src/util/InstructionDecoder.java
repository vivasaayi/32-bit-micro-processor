package util;

import java.util.HashMap;
import java.util.Map;

/**
 * Shared instruction decoder for both Hex and SimulationLog tabs
 */
public class InstructionDecoder {
    
    private static final Map<Integer, String> OPCODE_MAP = new HashMap<>();
    
    static {
        // Common opcodes based on simulation log
        OPCODE_MAP.put(0x00, "NOP");
        OPCODE_MAP.put(0x02, "LOAD");
        OPCODE_MAP.put(0x04, "ADD");
        OPCODE_MAP.put(0x06, "SUB");
        OPCODE_MAP.put(0x08, "MOV");
        OPCODE_MAP.put(0x0A, "ADDI");
        OPCODE_MAP.put(0x20, "SETEQ");
        OPCODE_MAP.put(0x24, "SETC");
        OPCODE_MAP.put(0x26, "SETZ");
        OPCODE_MAP.put(0x36, "SETN");
        OPCODE_MAP.put(0x38, "HALT");
        OPCODE_MAP.put(0x3E, "SETV");
        // Add more opcodes as needed
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
            case "ADDI":
                return String.format("R%d = R%d + %d", rd, rs1, imm);
            case "SUB":
                return String.format("R%d = R%d - R%d", rd, rs1, rs2);
            case "MOV":
                return String.format("R%d = R%d", rd, rs1);
            case "LOAD":
                return String.format("R%d = MEM[R%d + %d]", rd, rs1, imm);
            case "HALT":
                return "Stop execution";
            case "NOP":
                return "No operation";
            default:
                return String.format("Operation %s", mnemonic);
        }
    }
    
    public static String getOpcodeName(int opcode) {
        return OPCODE_MAP.getOrDefault(opcode, "OP_" + String.format("%02X", opcode));
    }
}
