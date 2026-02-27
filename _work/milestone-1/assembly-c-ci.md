# Goals:
As we make enhancements to our RISC Core, Assembler, Compiler, or OS, we should ensure 0 regressions.

All of our Assembly Programs and C Programs should work.


## Detecting C Regressions:
1. AruviCompiler should compile all programs to RISC Assembly
2. Then assemble them using AruviAsm into Hex
3. Load the hex and execute using AruviCore

## Detecting Assembly Regressions:
1. AruvASM should compile the assembly programs to HEX
2. Load the Hex using AruviCore

# CI Expectations
1. We should expose a single command in the project root to run the regression tests (unit, integration etc)
2. We should also execute this in the Github CI and block build if there are regressions