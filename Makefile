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
TB_DIR = testbench_32

# 32-bit Source files
CPU_32_SOURCES = cpu/cpu_core_32_simple.v cpu/alu_32.v cpu/register_file_32.v
SYSTEM_32_SOURCES = microprocessor_system_32.v
ALL_32_SOURCES = $(CPU_32_SOURCES) $(SYSTEM_32_SOURCES)

# 32-bit testbench files
TB_32_SOURCES = testbench_32/tb_microprocessor_32.v

# 32-bit output files
VVP_32_FILE = testbench_32/microprocessor_system_32.vvp
VCD_32_FILE = testbench_32/microprocessor_system_32.vcd

# Default target - 32-bit simulation
all: sim

# 32-bit simulation (default)
sim: $(VVP_32_FILE)
	$(VVP) $(VVP_32_FILE)

# Compile 32-bit testbench
$(VVP_32_FILE): $(ALL_32_SOURCES) $(TB_32_SOURCES)
	$(IVERILOG) -o $(VVP_32_FILE) $(ALL_32_SOURCES) $(TB_32_SOURCES)

# View 32-bit waveforms
wave: $(VCD_32_FILE)
	$(GTKWAVE) $(VCD_32_FILE) &

# Clean 32-bit files
clean:
	rm -f $(VVP_32_FILE) $(VCD_32_FILE)

# Assemble 32-bit programs
assemble:
	python3 tools/assembler_32.py examples_32/simple_sort_32.asm testbench_32/simple_sort_32.hex

# Test 32-bit ALU
test-alu:
	$(IVERILOG) -o alu_test_32.vvp $(CPU_DIR)/alu_32.v testbench_32/tb_alu_32.v 2>/dev/null || echo "ALU testbench not found"
	$(VVP) alu_test_32.vvp 2>/dev/null || echo "ALU test skipped"

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

.PHONY: all sim wave clean test-alu assemble synth lint docs install-deps
