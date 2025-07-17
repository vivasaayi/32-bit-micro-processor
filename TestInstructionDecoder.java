public class TestInstructionDecoder {
    public static void main(String[] args) {
        // Test machine codes from assembler output
        int[] testInstructions = {
            0x48480000, // LOADI R9, #0
            0x48512C00, // LOADI R10, #76800  
            0x4868803C  // LOADI R13, #0x803C
        };
        
        for (int i = 0; i < testInstructions.length; i++) {
            Object[] decoded = util.InstructionDecoder.decodeInstruction(i * 4, testInstructions[i]);
            System.out.printf("0x%08X: %s %s %s %s %s %s - %s%n", 
                testInstructions[i],
                decoded[1], // opcode
                decoded[6], // mnemonic  
                decoded[2], // rd
                decoded[5], // immediate
                decoded[3], // rs1
                decoded[4], // rs2
                decoded[7]  // comment
            );
        }
    }
}
