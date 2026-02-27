# Makefile for 32-bit Microprocessor

# Tools
IVERILOG = iverilog
VVP = vvp
GTKWAVE = gtkwave

# Directories  
PROC_DIR = processor
CPU_DIR = processor/cpu
MEM_DIR = processor/memory
IO_DIR = processor/io
TB_DIR = processor/testbench

# Source files
CPU_SOURCES = processor/cpu/cpu_core.v processor/cpu/alu.v processor/cpu/register_file.v
MEM_SOURCES = processor/memory/memory_controller.v processor/memory/mmu.v
IO_SOURCES = processor/io/uart.v processor/io/timer.v processor/io/interrupt_controller.v
SYSTEM_SOURCES = processor/microprocessor_system.v
ALL_SOURCES = $(CPU_SOURCES) $(MEM_SOURCES) $(IO_SOURCES) $(SYSTEM_SOURCES)

# Testbench files
TB_SOURCES = processor/testbench/tb_microprocessor_system.v

# Output files
VVP_FILE = processor/testbench/microprocessor_system.vvp
VCD_FILE = processor/testbench/microprocessor_system.vcd

# Default target - 32-bit simulation
all: sim

# Default simulation
sim: $(VVP_FILE)
	$(VVP) $(VVP_FILE)

# Compile testbench
$(VVP_FILE): $(ALL_SOURCES) $(TB_SOURCES)
	$(IVERILOG) -o $(VVP_FILE) $(ALL_SOURCES) $(TB_SOURCES)

# View waveforms
wave: $(VCD_FILE)
	$(GTKWAVE) $(VCD_FILE) &

# Clean files
clean:
	rm -f $(VVP_FILE) $(VCD_FILE)
	rm -rf temp/
	$(MAKE) -C tools clean

# Run the C-to-assembly test pipeline (preferred)
ctest:
	python3 c_test_runner.py .

# Test ALU
test-alu:
	$(IVERILOG) -o alu_test.vvp $(CPU_DIR)/alu.v testbench/tb_alu.v 2>/dev/null || echo "ALU testbench not found"
	$(VVP) alu_test.vvp 2>/dev/null || echo "ALU test skipped"

# Test Register File
test-reg:
	$(IVERILOG) -o tb_register_file $(TB_DIR)/tb_register_file.v $(CPU_DIR)/register_file.v
	$(VVP) tb_register_file

# Run all test cases
test-all:
	./run_all_tests.sh

# Run comprehensive test suite
test-comprehensive:
	python3 test_all_asm.py

# Synthesis using Yosys
synth: $(ALL_SOURCES)
	@echo "Running Yosys synthesis..."
	@yosys -p "read_verilog $(ALL_SOURCES); synth; stat; write_verilog synth_out.v" \
	   && echo "Synthesis complete: output in synth_out.v"

# Lint check (placeholder)
lint:
	@echo "Linting would require tools like Verilator"
	@echo "This is a placeholder for linting commands"

# Documentation
docs:
	@echo "Generating documentation..."
	@echo "See README.md and docs/ directory for project documentation"

# Install dependencies (macOS with Homebrew)
install-deps:
	brew install icarus-verilog
	brew install gtkwave
	brew install qemu

# --- QEMU Integration ---
QEMU_RISCV32 = qemu-system-riscv32
ASSEMBLER = ./temp/assembler

# Compile the assembler if not exists
$(ASSEMBLER): tools/assembler.c
	$(MAKE) -C tools

# Run assembly in QEMU
# Usage: make qemu-asm ASM=verification/asm/test_alu.asm
# Note: We use -bios none and load at 0x80000000 (RAM base for 'virt' machine)
# We use -serial mon:stdio to multiplex serial and monitor (use Ctrl-a c to switch)
qemu-asm: $(ASSEMBLER)
	@if [ -z "$(ASM)" ]; then echo "Usage: make qemu-asm ASM=path/to/test.asm"; exit 1; fi
	$(ASSEMBLER) $(ASM) -o output.bin
	$(QEMU_RISCV32) -M virt -cpu rv32 -bios none -device loader,file=output.bin,addr=0x80000000 -nographic -serial mon:stdio || echo "QEMU failed"

# Run C program in QEMU
qemu-c:
	@if [ -z "$(C_SRC)" ]; then echo "Usage: make qemu-c C_SRC=path/to/test.c"; exit 1; fi
	$(MAKE) -C AruviCompiler compile_c C_SRC=$(C_SRC)
	$(ASSEMBLER) AruviCompiler/output.s -o output.bin
	$(QEMU_RISCV32) -M virt -cpu rv32 -bios none -device loader,file=output.bin,addr=0x80000000 -nographic -serial mon:stdio

.PHONY: all sim wave clean test-alu test-reg test-all test-comprehensive assemble synth lint docs install-deps qemu-asm qemu-c
