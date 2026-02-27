I loaded a C file, compiled it. The assemble file name is shown as C. INstead it should show the actual compiled assemble file name.

Hex tab done show the rendered hex file location.

I think you need to add a button in the HEX tab, "Load and Test Hex", and when that button is clicked, 

Thought: Generate theh V file using the c_test_runner, (/Users/rajanpanneerselvam/work/hdl/c_test_runner.py).. You also need to update/refactor c_test_runner to add an additional command to genetate the test bench file. The cpmmand I shared eaerlier, generates the test bench, then exectes generates VVP and then executes the VVP. Thats a whole lot of process.

Compile Command: ['iverilog', '-o', 'temp/tb_105_manual_graphics.vvp', 'temp/tb_105_manual_graphics.v', 'processor/microprocessor_system.v', 'processor/cpu/cpu_core.v', 'processor/cpu/alu.v', 'processor/cpu/register_file.v', 'processor/memory/memory_controller.v', 'processor/memory/mmu.v', 'processor/io/uart.v', 'processor/io/timer.v', 'processor/io/interrupt_controller.v']
VVP Command:  ['vvp', 'temp/tb_105_manual_graphics.vvp']

What can we do: I want to break that down. 

Lets extract the V file and VVP file out. So expose on tab saying "V/VVP". Update the file loader to allow V filed (no VVP). Move the current V, VVP tabs to this new "V/VVP" tab.

Its much better if you extract and  testbench generation to java. The functionality works as below: Add one more tab which shows the testbench template, in an edtior, so that I can modify the template and save as required. This tab is always visible as of now. Then when I say "Load and Test Hex", then first using the testbech template, and the hex file selected, render the test bench v file and load the V tab under "V/VVP".

As oart of this, after the V file generation, you can generate the VVP file. Also In the V files tab, add a button, so that I can dynamically genetate teh VVP also - will be useful for debugging. Provide a save button to save the V file to disk (at this point I dont wnat to load the V file)

Keep the simulation tab.. 