CMP (Compare Register)
Opcode: ALU_CMP = 0x0B
Format: CMP Rs1, Rs2
Operation: Compares the value in register Rs1 with the value in register Rs2.
Effect: Updates the CPU flags (Zero, Negative, Carry, Overflow) based on the result of the subtraction Rs1 - Rs2.
No Register Write: CMP does not write any result to a register; it only affects the flags.
Typical Use: Used for conditional branching or set instructions that depend on comparison results.
CMPI (Compare Immediate)
Opcode: ALU_CMPI = 0x0F
Format: CMPI Rs, #imm
Operation: Compares the value in register Rs with an immediate value imm.
Effect: Updates the CPU flags (Zero, Negative, Carry, Overflow) based on the result of the subtraction Rs - imm.
No Register Write: CMPI does not write any result to a register; it only affects the flags.
Typical Use: Useful for comparing a register directly to a constant, enabling efficient range checks and conditional logic.
Summary:
Both CMP and CMPI are non-destructive comparison instructions. They do not modify register contents, but update the processor flags to reflect the result of the comparison. This allows subsequent conditional instructions (like branches or set instructions) to act based on the outcome. CMP compares two registers, while CMPI compares a register to an immediate value.