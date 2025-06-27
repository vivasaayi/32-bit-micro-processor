`timescale 1ns / 1ps

module debug_instructions;
    
    // Debug assembler-generated instructions
    initial begin
        $display("=== Analyzing assembler-generated hex file ===");
        
        // From hex file at 0x8000:
        // 32 0A 32 05 00 32 FF 32 0F 10 32 14 32 08 1A 80 44 15 80 32 2A 64
        
        $display("Instruction Analysis:");
        $display("0x32 0x0A - Expected: LOADI R0, #10");
        $display("0x32 0x05 - Expected: LOADI R1, #5");
        $display("0x00      - Expected: ADD R0, R1");
        $display("0x32 0xFF - Expected: LOADI R2, #0xFF");
        $display("0x32 0x0F - Expected: LOADI R3, #0x0F");
        $display("0x10      - Expected: AND R2, R3");
        $display("0x32 0x14 - Expected: LOADI R4, #20");
        $display("0x32 0x08 - Expected: LOADI R5, #8");
        $display("0x1A      - Expected: SUB R4, R5");
        $display("0x80      - Expected: CMP R0, R1");
        $display("0x44      - Expected: JGE end");
        $display("0x15 0x80 - Expected: JGE address");
        $display("0x32 0x2A - Expected: LOADI R7, #42");
        $display("0x64      - Expected: HALT");
        
        $display("=== CPU Expected Instruction Format ===");
        $display("Based on control_unit.v:");
        $display("LOADI: opcode=4'h4, sub=2'b10, reg=3'b[reg] => 0100[reg]10 = 0x4[reg]2");
        $display("ADD:   opcode=4'h0, reg1, reg2 => 0000[reg1][reg2]");
        $display("AND:   opcode=4'h2, sub=2'b00 => 0010[reg1][reg2]00");
        $display("SUB:   opcode=4'h1, sub=2'b00 => 0001[reg1][reg2]00");
        $display("CMP:   opcode=4'h8 => 1000[reg1][reg2]");
        $display("JGE:   opcode=4'h5, sub=3'b100 => 01010100");
        $display("HALT:  opcode=4'h7, instr=8'h64 => 01100100");
        
        $display("=== Instruction Mismatch Found ===");
        $display("The assembler is generating different opcodes than CPU expects!");
        $display("Need to check assembler instruction encoding.");
    end
    
endmodule
