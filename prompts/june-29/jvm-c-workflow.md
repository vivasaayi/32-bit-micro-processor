Thats great!

Lets work towards operationalizing the minimal JVM..

That way, we can demonstrate that our processor can execute simple C & JAVA programs.. Then we can continue iterating..

By end of this work, I want to have,

1. Our Own C Compiler - that can compile simple C Programs. As well us it will be able to compile our JVM.
2. Our own assembler - whichc will generate machine code based on the RISC processor
3. The test bench or the runner script - which will load the generated hex into our processor and execute it. 
4. The test bench also capable of loading the JVM hex, and java byte code and execute it.

To explain in detail,

I have below folders which contains the source programs.

1. /Users/rajanpanneerselvam/work/hdl/test_programs/c - which stores my C programs. 
2. /Users/rajanpanneerselvam/work/hdl/test_programs/java - which stores my Java programs
3. /Users/rajanpanneerselvam/work/hdl/test_programs/assembly - which stores my assembly programs (dont confuse this with the intermediate assembly generated. This is my own handcrafted real programs)
4. /Users/rajanpanneerselvam/work/hdl/jvm - This is my JVM C Code (we need to use a working one)

JVM Preparation:
We need to have one command, which will compile the JVM and make it ready (gnerate the hex)

I have a well working C Flow;
/Users/rajanpanneerselvam/work/hdl/run_one_test.sh - this file will use the c_test_runner to compile the C programs from the above source and execute it using the processor

For the Java workflow;
We have this: /Users/rajanpanneerselvam/work/hdl/run_java_programs.sh - But it is not doing what we expect.

The JAVA flow I need,
1. Specify the JAVA program
2. Generate the bytecode using standard java tool chain
3. Load the byte code generated for the java progam into one memory location
4. Load the JVM hex in to my RISC (kinda JavaOS) - and execute the program

Later, I want the JavaOs, to list the available programs and execute the one I want - a simple CLI.

As part this,
1. Enhance the processor/instruciton sets
2. Enhance the assembler 
3. Enhance the compiler.

If you see any gaps, call out what need to be done in all three layers and we can perform it.