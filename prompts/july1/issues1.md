Error loading the generated assembly.. I noted that the filepath follows anming convention.. But the console show this:

Starting compilation...
STDOUT: Compiling '/Users/rajanpanneerselvam/work/hdl/test_programs/c/02_arithmetic.c' to 'output.s'...
STDOUT: Lexical analysis: 109 tokens
STDOUT: Parsing: AST generated
STDOUT: Type checking: passed
STDOUT: Code generation: completed successfully
STDOUT: Assembly written to 'output.s'
Compilation successful!


Simulation experience is still not good. can you add an button to generate the test benech files? and then generate the VVP filed? You can use the c_test_runner in th8is project. This is how I run an individual file and the result of V, VVP file generatipon and execution.

cd /Users/rajanpanneerselvam/work/hdl && python3 c_test_runner.py . --test 105_manual_graphics --type assembly
🚀 Running single Assembly test: 105_manual_graphics
Stage 1: Assembling to Hex...
Assembly file name: test_programs/asm/105_manual_graphics.asm
Hex file generated: temp/c_generated_hex/105_manual_graphics.hex
  ✅ Assembly successful
Stage 2: Running Simulation...
Using framebuffer testbench for graphics test: 105_manual_graphics
Test Bench file: temp/tb_105_manual_graphics.v
VVD File: temp/tb_105_manual_graphics.vvp
Compile Command: ['iverilog', '-o', 'temp/tb_105_manual_graphics.vvp', 'temp/tb_105_manual_graphics.v', 'processor/microprocessor_system.v', 'processor/cpu/cpu_core.v', 'processor/cpu/alu.v', 'processor/cpu/register_file.v', 'processor/memory/memory_controller.v', 'processor/memory/mmu.v', 'processor/io/uart.v', 'processor/io/timer.v', 'processor/io/interrupt_controller.v']
VVP Command:  ['vvp', 'temp/tb_105_manual_graphics.vvp']