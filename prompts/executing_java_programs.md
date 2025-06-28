Goal: I want the capability to load and execute Java Programs in my RISC processor.

I have implemented a small Java byte code interpreter.. That is a seperate git repo and uses standard C toolchain and executable in Mac.

What I want is, I want the same byte code interpreter to be compilable via my own C Compiler, and executed via my RISC processor.

What I have,
1. I have simple java programs: in this folder: /Users/rajanpanneerselvam/work/hdl/AruviJVM/examples
2. I have Byte code converter: /Users/rajanpanneerselvam/work/hdl/AruviJVM/tools/bytecode_converter.py
3. Existing JVM interpreter: /Users/rajanpanneerselvam/work/hdl/AruviJVM/src


What I need,
1. Compile the JVM interpreter using my C Compiler: /Users/rajanpanneerselvam/work/hdl/tools/c_compiler.c
2. Assemnle the JAM interpreter using my assembler: /Users/rajanpanneerselvam/work/hdl/tools/assembler.c
3. Create a test bench that will load the JVM interpreter, along with wihch bytecode program to execute, follwoing the existing exammples /Users/rajanpanneerselvam/work/hdl/c_test_runner.py, /Users/rajanpanneerselvam/work/hdl/run_one_test.sh
4. Demonstrate the Java programs can be interpreted in my RISC Processor.

Along the lines,
1. I want to enhance my RISC instruction set - So make a clear case for the change, document it and make the change.
2. My assembler should be updated to match the RISC instruction set without breaking existing code - Also I am open to change existing code if you think they need modification - make a case, document it and do it
3. Enhance my Compiler

Refer exisitng prompts; /Users/rajanpanneerselvam/work/hdl/prompts/test_goal.md /Users/rajanpanneerselvam/work/hdl/prompts/toolchain.md