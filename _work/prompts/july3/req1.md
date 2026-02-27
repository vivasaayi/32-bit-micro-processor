I want to ehance the debuggubality of the simlog.

In the simlog tab, I want to show the decoded opcodes table. We have this table in the Hex tab. 

So, the changes are,
1. Always decde Hex, you can remove the button in the HEx Tab, 
2. Show the decoded Hex table in both Hex Tab, and the SimulationLog Tab

Parsing the Sim Log, refer my simulation log, For more detais you can check this file: /Users/rajanpanneerselvam/work/hdl/prompts/july3/temp_assembly.log


I think we can parse this and show a visual representation of what happened in a table.

The table will look ike,
PG, OpCode, Short OpCode Human Text, RD, RS1, RS2, IMM etc, X1-X32

The impacted register cell wil be highlihgted in green

```
SIM: WARNING: /Users/rajanpanneerselvam/work/hdl/temp/temp_assembly_testbench.v:100: $readmemh(/var/folders/q_/ftgm2b891n5dj7ncj244yms40000gn/T/temp_assembly.hex): Not enough words in the file for the requested range [8192:262143].
SIM: DEBUG ALU ADD: a=0 b=0 result=0
SIM: DEBUG CPU Execute: PC=0x00008004, Opcode=04, rd= 1, rs1= 0, rs2= 0, imm=00000000
SIM: DEBUG CPU ALU:  ADD rd= 1, rs1= 0, val2=         0, result=         0
SIM: DEBUG CPU Execute: Instruction opcode=04, alu_result=         0, alu_result_reg will be set to          0
SIM: DEBUG CPU: Flags updated to C=0 Z=1 N=0 V=0
SIM: DEBUG: Checking SET condition: opcode=04, OP_SETEQ=20, condition=0
SIM: DEBUG ALU: ADD/ADDI - op= ADD R 1 = R 0 + R         0 =>          0
SIM: DEBUG ALU ADD: a=0 b=0 result=0
SIM: DEBUG CPU Writeback: Writing          0 to R 1
SIM: DEBUG CPU Execute: PC=0x00008008, Opcode=08, rd= 2, rs1= 1, rs2= 0, imm=00000000
SIM: DEBUG CPU Execute: Instruction opcode=08, alu_result=         0, alu_result_reg will be set to          0
SIM: DEBUG CPU: Flags updated to C=0 Z=1 N=0 V=0
SIM: DEBUG: Checking SET condition: opcode=08, OP_SETEQ=20, condition=0
SIM: DEBUG CPU Writeback: Writing          0 to R 2
SIM: DEBUG CPU Execute: PC=0x0000800c, Opcode=06, rd= 2, rs1= 0, rs2= 0, imm=00000000
SIM: DEBUG CPU Execute: Instruction opcode=06, alu_result=         0, alu_result_reg will be set to          0
SIM: DEBUG CPU: Flags updated to C=0 Z=1 N=0 V=0
SIM: DEBUG: Checking SET condition: opcode=06, OP_SETEQ=20, condition=0
SIM: DEBUG CPU Writeback: Writing          0 to R 2
SIM: DEBUG CPU Execute: PC=0x00008010, Opcode=08, rd= 0, rs1= 1, rs2= 0, imm=00000000
SIM: DEBUG CPU Execute: Instruction opcode=08, alu_result=         0, alu_result_reg will be set to          0
SIM: DEBUG CPU: Flags updated to C=0 Z=1 N=0 V=0
SIM: DEBUG: Checking SET condition: opcode=08, OP_SETEQ=20, condition=0
SIM: DEBUG CPU Writeback: Writing          0 to R 0
SIM: DEBUG ALU ADD: a=0 b=0 result=0
SIM: DEBUG CPU Execute: PC=0x00008014, Opcode=38, rd= 0, rs1= 0, rs2= 0, imm=00000000
SIM: DEBUG CPU Execute: Instruction opcode=38, alu_result=         0, alu_result_reg will be set to          0
SIM: DEBUG: Checking SET condition: opcode=38, OP_SETEQ=20, condition=0
SIM: DEBUG CPU Writeback: Writing          0 to R 0
SIM: DEBUG CPU Execute: PC=0x00008018, Opcode=00, rd= 0, rs1= 0, rs2= 0, imm=00000000
SIM: DEBUG CPU Execute: Instruction opcode=00, alu_result=         0, alu_result_reg will be set to          0
SIM: DEBUG: Checking SET condition: opcode=00, OP_SETEQ=20, condition=0
SIM: DEBUG CPU Writeback: Writing          0 to R 0
SIM: DEBUG CPU Execute: PC=0x0000801c, Opcode=38, rd= 0, rs1= 0, rs2= 0, imm=00000000
SIM: DEBUG CPU Execute: Instruction opcode=38, alu_result=         0, alu_result_reg will be set to          0
SIM: DEBUG: Checking SET condition: opcode=38, OP_SETEQ=20, condition=0
SIM: DEBUG CPU Writeback: Writing          0 to R 0
SIM: DEBUG CPU Execute: PC=0x00008020, Opcode=08, rd= 1, rs1= 0, rs2= 0, imm=00000000
SIM: DEBUG CPU Execute: Instruction opcode=08, alu_result=         0, alu_result_reg will be set to          0
SIM: DEBUG CPU: Flags updated to C=0 Z=1 N=0 V=0
SIM: DEBUG: Checking SET condition: opcode=08, OP_SETEQ=20, condition=0
SIM: DEBUG CPU Writeback: Writing          0 to R 1
SIM: DEBUG ALU ADD: a=0 b=0 result=0
SIM: DEBUG CPU Execute: PC=0x00008024, Opcode=02, rd= 0, rs1= 0, rs2= 0, imm=00000000
SIM: DEBUG CPU Execute: Instruction opcode=02, alu_result=         0, alu_result_reg will be set to          0
SIM: DEBUG: Checking SET condition: opcode=02, OP_SETEQ=20, condition=0
```

