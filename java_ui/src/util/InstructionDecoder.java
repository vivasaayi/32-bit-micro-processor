package util;

import java.util.HashMap;
import java.util.Map;

/**
 * Custom CPU Instruction Decoder
 * Based on /Users/rajanpanneerselvam/work/hdl/processor/cpu/cpu_core.v
 * 
 * Instruction Format:
 * [31:26] - Opcode (6 bits)
 * [25:24] - Mode/Sub-function (2 bits)
 * [23:19] - RD (5 bits)
 * [18:14] - RS1 (5 bits)
 * [13:9]  - RS2 (5 bits)
 * [8:0]   - Immediate (9 bits) or [18:0] for 19-bit immediate
 */
public class InstructionDecoder {
    
    // Instruction opcodes from cpu_core.v
    private static final Map<Integer, String> OPCODES = new HashMap<>();
    
    static {
        // ALU operations
        OPCODES.put(0x00, "ADD");
        OPCODES.put(0x01, "SUB");
        OPCODES.put(0x02, "ADDI");
        OPCODES.put(0x03, "SUBI");
        OPCODES.put(0x04, "AND");
        OPCODES.put(0x05, "OR");
        OPCODES.put(0x06, "XOR");
        OPCODES.put(0x07, "NOT");
        OPCODES.put(0x08, "SHL");
        OPCODES.put(0x09, "SHR");
        OPCODES.put(0x0A, "LOAD");
        OPCODES.put(0x0B, "STORE");
        OPCODES.put(0x0C, "CMP");
        OPCODES.put(0x0D, "LOADI");
        OPCODES.put(0x0E, "MUL");
        OPCODES.put(0x0F, "DIV");
        OPCODES.put(0x10, "MOD");
        
        // Branch/jump instructions
        OPCODES.put(0x11, "CMP");
        OPCODES.put(0x12, "JMP");
        OPCODES.put(0x13, "JZ");
        OPCODES.put(0x14, "JNZ");
        OPCODES.put(0x15, "JC");
        OPCODES.put(0x16, "JNC");
        OPCODES.put(0x17, "JLT");
        OPCODES.put(0x18, "JGE");
        OPCODES.put(0x19, "JLE");
        OPCODES.put(0x1A, "JN");
        OPCODES.put(0x1B, "CALL");
        OPCODES.put(0x1C, "RET");
        OPCODES.put(0x1D, "PUSH");
        OPCODES.put(0x1E, "POP");
        OPCODES.put(0x1F, "HALT");
        
        // Set/compare instructions
        OPCODES.put(0x20, "SETEQ");
        OPCODES.put(0x21, "SETNE");
        OPCODES.put(0x22, "SETLT");
        OPCODES.put(0x23, "SETGE");
        OPCODES.put(0x24, "SETLE");
        OPCODES.put(0x25, "SETGT");
    }
    
    public static class DecodedInstruction {
        public int opcode;
        public String mnemonic;
        public int rd;
        public int rs1;
        public int rs2;
        public int immediate;
        public boolean hasImmediate;
        public String comment;
        
        public DecodedInstruction(int opcode, String mnemonic, int rd, int rs1, int rs2, int immediate, boolean hasImmediate) {
            this.opcode = opcode;
            this.mnemonic = mnemonic;
            this.rd = rd;
            this.rs1 = rs1;
            this.rs2 = rs2;
            this.immediate = immediate;
            this.hasImmediate = hasImmediate;
            this.comment = generateComment();
        }
        
        private String generateComment() {
            switch (mnemonic) {
                case "ADD": return String.format("R%d = R%d + R%d", rd, rs1, rs2);
                case "SUB": return String.format("R%d = R%d - R%d", rd, rs1, rs2);
                case "ADDI": return String.format("R%d = R%d + %d", rd, rs1, immediate);
                case "SUBI": return String.format("R%d = R%d - %d", rd, rs1, immediate);
                case "AND": return String.format("R%d = R%d & R%d", rd, rs1, rs2);
                case "OR": return String.format("R%d = R%d | R%d", rd, rs1, rs2);
                case "XOR": return String.format("R%d = R%d ^ R%d", rd, rs1, rs2);
                case "NOT": return String.format("R%d = ~R%d", rd, rs1);
                case "SHL": return String.format("R%d = R%d << R%d", rd, rs1, rs2);
                case "SHR": return String.format("R%d = R%d >> R%d", rd, rs1, rs2);
                case "LOAD": return String.format("R%d = MEM[R%d + %d]", rd, rs1, immediate);
                case "STORE": return String.format("MEM[R%d + %d] = R%d", rs1, immediate, rd);
                case "LOADI": return String.format("R%d = %d", rd, immediate);
                case "CMP": return String.format("Compare R%d with R%d", rs1, rs2);
                case "JMP": return String.format("Jump to address %d", immediate);
                case "JZ": return String.format("Jump if zero to %d", immediate);
                case "JNZ": return String.format("Jump if not zero to %d", immediate);
                case "JC": return String.format("Jump if carry to %d", immediate);
                case "JNC": return String.format("Jump if no carry to %d", immediate);
                case "CALL": return String.format("Call function at %d", immediate);
                case "RET": return "Return from function";
                case "PUSH": return String.format("Push R%d onto stack", rs1);
                case "POP": return String.format("Pop from stack to R%d", rd);
                case "HALT": return "Halt processor";
                default: return "Unknown instruction";
            }
        }
    }
    
    /**
     * Decode a 32-bit instruction word
     */
    public static DecodedInstruction decode(int instruction) {
        int opcode = (instruction >>> 26) & 0x3F;  // [31:26]
        int rd = (instruction >>> 19) & 0x1F;      // [23:19] 
        int rs1 = (instruction >>> 14) & 0x1F;     // [18:14]
        int rs2 = (instruction >>> 9) & 0x1F;      // [13:9]
        
        String mnemonic = OPCODES.getOrDefault(opcode, "UNKNOWN");
        
        // Determine if instruction uses immediate
        boolean hasImmediate = isImmediateInstruction(opcode);
        int immediate = 0;
        
        if (hasImmediate) {
            if (opcode == 0x02 || opcode == 0x03) { // ADDI, SUBI - use 20-bit immediate
                immediate = instruction & 0xFFFFF; // [19:0]
                // Sign extend
                if ((immediate & 0x80000) != 0) {
                    immediate |= 0xFFF00000;
                }
            } else { // Other immediate instructions use 9-bit immediate
                immediate = instruction & 0x1FF; // [8:0]
                // Sign extend
                if ((immediate & 0x100) != 0) {
                    immediate |= 0xFFFFFE00;
                }
            }
        }
        
        return new DecodedInstruction(opcode, mnemonic, rd, rs1, rs2, immediate, hasImmediate);
    }
    
    /**
     * Check if instruction uses immediate operand
     */
    private static boolean isImmediateInstruction(int opcode) {
        return opcode == 0x02 || // ADDI
               opcode == 0x03 || // SUBI  
               opcode == 0x0A || // LOAD
               opcode == 0x0B || // STORE
               opcode == 0x0D || // LOADI
               (opcode >= 0x12 && opcode <= 0x1B); // Jump/branch instructions
    }
    
    /**
     * Format instruction as assembly string
     */
    public static String formatAsAssembly(DecodedInstruction inst) {
        if (inst.hasImmediate) {
            switch (inst.mnemonic) {
                case "ADDI":
                case "SUBI":
                    return String.format("%s R%d, R%d, %d", inst.mnemonic, inst.rd, inst.rs1, inst.immediate);
                case "LOADI":
                    return String.format("%s R%d, %d", inst.mnemonic, inst.rd, inst.immediate);
                case "LOAD":
                    return String.format("%s R%d, [R%d + %d]", inst.mnemonic, inst.rd, inst.rs1, inst.immediate);
                case "STORE":
                    return String.format("%s [R%d + %d], R%d", inst.mnemonic, inst.rs1, inst.immediate, inst.rd);
                case "JMP":
                case "JZ":
                case "JNZ":
                case "JC":
                case "JNC":
                case "CALL":
                    return String.format("%s %d", inst.mnemonic, inst.immediate);
                default:
                    return String.format("%s %d", inst.mnemonic, inst.immediate);
            }
        } else {
            switch (inst.mnemonic) {
                case "RET":
                case "HALT":
                    return inst.mnemonic;
                case "NOT":
                case "PUSH":
                    return String.format("%s R%d", inst.mnemonic, inst.rs1);
                case "POP":
                    return String.format("%s R%d", inst.mnemonic, inst.rd);
                case "CMP":
                    return String.format("%s R%d, R%d", inst.mnemonic, inst.rs1, inst.rs2);
                default:
                    return String.format("%s R%d, R%d, R%d", inst.mnemonic, inst.rd, inst.rs1, inst.rs2);
            }
        }
    }
}
