Here is a table of your CPU core opcodes and mnemonics, with each opcode value shown in binary, octal, hex, and decimal, along with a brief description:

Mnemonic	Binary	Octal	Hex	Dec	Description
ALU_ADD	000000	00	0x00	0	a + b
ALU_SUB	000001	01	0x01	1	a - b
ALU_AND	000010	02	0x02	2	a & b
ALU_OR	000011	03	0x03	3	a | b
ALU_XOR	000100	04	0x04	4	a ^ b
ALU_NOT	000101	05	0x05	5	~a
ALU_SHL	000110	06	0x06	6	a << b
ALU_SHR	000111	07	0x07	7	a >> b
ALU_MUL	001000	10	0x08	8	a * b
ALU_DIV	001001	11	0x09	9	a / b
ALU_MOD	001010	12	0x0A	10	a % b
ALU_CMP	001011	13	0x0B	11	compare a, b
ALU_SAR	001100	14	0x0C	12	a >>> b (arith shift)
MEM_LOAD	100000	40	0x20	32	Load from memory
MEM_LOADI	100010	42	0x22	34	Load immediate value into register (R[rd] = imm)
MEM_STORE	100001	41	0x21	33	Store to memory
OP_JMP	110000	60	0x30	48	Unconditional jump
OP_JZ	110001	61	0x31	49	Jump if zero
OP_JNZ	110010	62	0x32	50	Jump if not zero
OP_JC	110011	63	0x33	51	Jump if carry
OP_JNC	110100	64	0x34	52	Jump if not carry
OP_JLT	110101	65	0x35	53	Jump if less than
OP_JGE	110110	66	0x36	54	Jump if greater/equal
OP_JLE	110111	67	0x37	55	Jump if less/equal
OP_CALL	111000	70	0x38	56	Call subroutine
OP_RET	111001	71	0x39	57	Return from subroutine
OP_PUSH	111010	72	0x3A	58	Push to stack
OP_POP	111011	73	0x3B	59	Pop from stack
OP_SETEQ	1000000	100	0x40	64	Set if equal
OP_SETNE	1000001	101	0x41	65	Set if not equal
OP_SETLT	1000010	102	0x42	66	Set if less than
OP_SETGE	1000011	103	0x43	67	Set if greater/equal
OP_SETLE	1000100	104	0x44	68	Set if less/equal
OP_SETGT	1000101	105	0x45	69	Set if greater than
OP_HALT*	1010000	120	0x50	80	Halt CPU
OP_INT*	1010001	121	0x51	81	Software interrupt
* Note: Only opcodes 0x00–0x3F (0–63) are unique for a 6-bit opcode field. Opcodes above 0x3F will be truncated (e.g., 0x50 becomes 0x10). For unique system instructions, use values ≤ 0x3F.

Let me know if you want this as a markdown table or need a specific subset!