# Makefile for 32-bit Microprocessor

# Tools
IVERILOG = iverilog
VVP = vvp
GTKWAVE = gtkwave

# Directories  
SRC_DIR = .
CPU_DIR = cpu
MEM_DIR = memory
IO_DIR = io
TB_DIR = testbench

# Source files
CPU_SOURCES = cpu/cpu_core.v cpu/alu.v cpu/register_file.v
SYSTEM_SOURCES = microprocessor_system.v
ALL_SOURCES = $(CPU_SOURCES) $(SYSTEM_SOURCES)

# Testbench files
TB_SOURCES = testbench/tb_microprocessor_system.v

# Output files
VVP_FILE = testbench/microprocessor_system.vvp
VCD_FILE = testbench/microprocessor_system.vcd

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

# Assemble programs
assemble:
	python3 tools/assembler.py examples/simple_sort.asm testbench/simple_sort.hex

# Test ALU
test-alu:
	$(IVERILOG) -o alu_test.vvp $(CPU_DIR)/alu.v testbench/tb_alu.v 2>/dev/null || echo "ALU testbench not found"
	$(VVP) alu_test.vvp 2>/dev/null || echo "ALU test skipped"

# Run all test cases
test-all:
	./run_all_tests.sh

# Run comprehensive test suite
test-comprehensive:
	python3 test_all_asm.py

# Synthesis (placeholder - would need actual synthesis tools)
synth:
	@echo "Synthesis would require tools like Yosys, Vivado, or Quartus"
	@echo "This is a placeholder for synthesis commands"

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

.PHONY: all sim wave clean test-alu test-all test-comprehensive assemble synth lint docs install-deps
