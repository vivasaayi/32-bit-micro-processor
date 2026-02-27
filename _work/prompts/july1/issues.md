1. In the CTab, I am able to see the program, click compile, which then uses my program to compile. The result is stored in STDOUT: Assembly written to 'output.s'. Then I wanted to go to teh assembly tab and see the generated assembly - the tab was disabled. From teh fix wise, can you write the output assembly with a specific naming convention and make the Assembly tab to load it by default? This will simplify my workflow. Basically the assembly tab will show the compile C assemly automatically, or use the opened assembly file. You need to manaage the Assemmbly tab loading according;y.

2. I noted the same Issue with assembly tab. When I click compile to hex, I expected the Hex Tab to load the genrated hex file. Also the I am using a custom assembly instructions and assembler - the explain contents need tailoring - we can save it for later.

3. The Hex decoder should be based on my processor - refer this file and implement the decoder: /Users/rajanpanneerselvam/work/hdl/processor/cpu/cpu_core.v.. Also, if I load the Hex file, I am not able to navigate to the assembler tab.. i should be able to navigate between the tabs so that I can retest the flows.. for ex, I load a C program, assemble it, checks the hEx, things are not good.. going back to teh C tab, change it coming back, The same for assembly.

4. In the simulation tab, 
seeing this in the simulaition lod: Initializing simulation...
ERROR: No VVP file found or Verilog compilation failed.. 
The verilog files and the VVP files tab is empty. Even If i click on start simulation the same things happes, Can you add some labels to the V and VVP file locations, so that I can also manually check them


If I change the file, then we have to reset all state, and the flow starts from the beginning.. I see the tabs are not cleared based on the input file change.