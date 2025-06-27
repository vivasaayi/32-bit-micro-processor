# Makefile for 8-bit Microprocessor

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
CPU_SOURCES = $(CPU_DIR)/cpu_core.v $(CPU_DIR)/alu.v $(CPU_DIR)/register_file.v $(CPU_DIR)/control_unit.v
MEM_SOURCES = $(MEM_DIR)/memory_controller.v $(MEM_DIR)/mmu.v
IO_SOURCES = $(IO_DIR)/uart.v $(IO_DIR)/timer.v $(IO_DIR)/interrupt_controller.v
SYSTEM_SOURCES = microprocessor_system.v
ALL_SOURCES = $(CPU_SOURCES) $(MEM_SOURCES) $(IO_SOURCES) $(SYSTEM_SOURCES)

# Testbench files
TB_SOURCES = $(TB_DIR)/tb_microprocessor_system.v

# Output files
VVP_FILE = microprocessor_system.vvp
VCD_FILE = microprocessor_system.vcd

# Default target
all: sim

# Compile and simulate
sim: $(VVP_FILE)
	$(VVP) $(VVP_FILE)

# Compile testbench
$(VVP_FILE): $(ALL_SOURCES) $(TB_SOURCES)
	$(IVERILOG) -o $(VVP_FILE) $(ALL_SOURCES) $(TB_SOURCES)

# View waveforms
wave: $(VCD_FILE)
	$(GTKWAVE) $(VCD_FILE) &

# Clean generated files
clean:
	rm -f $(VVP_FILE) $(VCD_FILE)

# Test individual modules
test-alu:
	$(IVERILOG) -o alu_test.vvp $(CPU_DIR)/alu.v $(TB_DIR)/tb_alu.v
	$(VVP) alu_test.vvp

test-cpu:
	$(IVERILOG) -o cpu_test.vvp $(CPU_SOURCES) $(TB_DIR)/tb_cpu_core.v
	$(VVP) cpu_test.vvp

test-uart:
	$(IVERILOG) -o uart_test.vvp $(IO_DIR)/uart.v $(TB_DIR)/tb_uart.v
	$(VVP) uart_test.vvp

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

.PHONY: all sim wave clean test-alu test-cpu test-uart synth lint docs install-deps
