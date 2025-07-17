 #python3 test_bouncing_rectangle.py

 temp/assembler /Users/rajanpanneerselvam/work/hdl/test_programs/asm/108_bouncing_rectangle_fixed.asm -o /Users/rajanpanneerselvam/work/hdl/temp/108_bouncing_rectangle_fixed.hex

 rm temp/reports/*
 
 cd temp

 
 iverilog -o 108_bouncing_rectangle_fixed_testbench_hc.vvp 108_bouncing_rectangle_fixed_testbench_hc.v ../processor/microprocessor_system.v ../processor/cpu/cpu_core.v ../processor/cpu/alu.v ../processor/cpu/register_file.v ../processor/memory/memory_controller.v
 vvp 108_bouncing_rectangle_fixed_testbench_hc.vvp
 
 cd ..
 python3 create_animation.py --input-dir temp/reports
 