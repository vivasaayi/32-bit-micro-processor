.Questions:

If you look at my repo, I am designing a custom RISC processor and a OS that can run on that processor.

I wanted to have full vertical.

The end goal:
1. FPGA that runs my RISC processor 
2. I load my OS on that RISC processor
3. I have my own C Compiler and using which I can compile C programs to assembkly
4. I have my own assembler and I can assemble the programs and generate RISC machine code
5. Load the machine code to my proessor and run the programs
6. I want to have my own JVM and run it in my RISC FPGA
7. Ability to run Java/Scala/Kotilin programs

As a testing bed:

1. I want to run my OS is Qemu, so that  I can run third party machine code and validate my OS.
2. Load stanard RISC OS in Qemu, so that I can run my compiler and assmbler and sprt our issues. 

By this cross testing, I can ensure that my AruviX platform is compatible with standard RISC