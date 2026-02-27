# Context

We have our own RISCV Compiler - AruviCompiler
We have our own RISCV Assembler - AruviAsm
We have our own RISCV microprocessor - AruviCore

We also have test C and Assembly programs, that we used to test our processor and AruviXPlatform.

# Certify RISCV Standard
At the end of day, we should establish ourselves as RISCV Certified.

Our toolchains should be RISCV certified.

We will start small.. But we will eventually become a full, mature suite.

# Though
What I am thking is that, 

1. Use AruviCompiler to compile our C Programs to RISCV Asm
2. Use AruviAsm to convert the RISCV Assemblky to Hex
3. Lets execute the HEX using a standard RISCV processor like Quemu
4. Assert AruviCompiler and AruviAsm are RISCV compatible

This will be a huge milestone for me.

What I will benefit:
1. No more tool hunting for FPGA Development
2. I will simply use AruviX platform to program an RISCV FPGA (third party core) - till I mature my AruviCore
3. I will be able to develop Hardware chain and the software toolset independantly, but together, without any block.