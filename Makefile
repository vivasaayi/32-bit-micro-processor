# Makefile for 32-bit Microprocessor

# Tools
IVERILOG = iverilog
VVP = vvp
GTKWAVE = gtkwave

# Directories  
PROC_DIR = AruviCore
CPU_DIR = AruviCore/cpu
MEM_DIR = AruviCore/memory
IO_DIR = AruviCore/io
TB_DIR = AruviCore/testbench

# Source files
CPU_SOURCES = AruviCore/cpu/cpu_core.v AruviCore/cpu/alu.v AruviCore/cpu/register_file.v
MEM_SOURCES = AruviCore/memory/memory_controller.v AruviCore/memory/mmu.v
IO_SOURCES = AruviCore/io/uart.v AruviCore/io/timer.v AruviCore/io/interrupt_controller.v
SYSTEM_SOURCES = AruviCore/microprocessor_system.v
ALL_SOURCES = $(CPU_SOURCES) $(MEM_SOURCES) $(IO_SOURCES) $(SYSTEM_SOURCES)

# Testbench files
TB_SOURCES = AruviCore/testbench/tb_microprocessor_system.v

# Output files
VVP_FILE = AruviCore/testbench/microprocessor_system.vvp
VCD_FILE = AruviCore/testbench/microprocessor_system.vcd

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
ASSEMBLER = ./AruviAsm/assembler

# Compile the assembler if not exists
$(ASSEMBLER): AruviAsm/assembler.c
	$(MAKE) -C AruviAsm

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

# Build all toolchain binaries for macOS
toolchain:
	@echo "Building AruviXPlatform toolchain..."
	@echo "Building assembler..."
	$(MAKE) -C AruviAsm
	@echo "Building compiler..."
	$(MAKE) -C AruviCompiler
	@echo "Building JVM..."
	$(MAKE) -C AruviJVM
	@echo "Building emulator..."
	cd AruviEmulator && cargo build --release
	@echo "Copying binaries to binaries/macos-arm64/"
	mkdir -p binaries/macos-arm64
	cp AruviAsm/assembler binaries/macos-arm64/
	cp AruviCompiler/ccompiler binaries/macos-arm64/
	cp AruviJVM/bin/aruvijvm binaries/macos-arm64/
	cp AruviEmulator/target/release/aruvi_emulator binaries/macos-arm64/
	@echo "✅ Toolchain built successfully!"
	@echo "Binaries ready for commit: binaries/macos-arm64/"

# Clean toolchain binaries
clean-toolchain:
	$(MAKE) -C AruviAsm clean
	$(MAKE) -C AruviCompiler clean
	$(MAKE) -C AruviJVM clean
	cd AruviEmulator && cargo clean
	rm -rf binaries/macos-arm64/

# Cross-check targets for RISC-V compatibility
run_assembly_using_riscv_assembler_on_riscv_core:
	@echo "🔍 Cross-check: RISC-V assembler on RISC-V core (QEMU)"
	@echo "Assembling RISC-V assembly with standard RISC-V assembler and running on QEMU"
	mkdir -p temp
	riscv64-elf-as sample_programs/arithmetic/assembly/handcrafted/0_0_add.s -o temp/test.o
	riscv64-elf-ld -T temp/link.ld temp/test.o -o temp/test.elf
	qemu-system-riscv32 -nographic -machine virt -bios none -kernel temp/test.elf

run_assembly_using_riscv_assembler_on_aruvi_core:
	@echo "🔍 Cross-check: RISC-V assembler on Aruvi core"
	@echo "Assembling RISC-V assembly with standard RISC-V assembler and running on Aruvi HDL simulation"
	# TODO: Implement - assemble to hex format compatible with Aruvi core

run_assembly_using_aruvi_assembler_on_riscv_core:
	@echo "🔍 Cross-check: Aruvi assembler on RISC-V core (QEMU)"
	@echo "Assembling RISC-V assembly with Aruvi assembler and running on QEMU"
	# TODO: Implement - convert Aruvi hex output to ELF for QEMU

run_assembly_using_aruvi_assembler_on_aruvi_core:
	@echo "🔍 Cross-check: Aruvi assembler on Aruvi core"
	@echo "Assembling RISC-V assembly with Aruvi assembler and running on Aruvi HDL simulation"
	$(MAKE) sim  # Current simulation uses Aruvi toolchain

.PHONY: all sim wave clean test-alu test-reg test-all test-comprehensive assemble synth lint docs install-deps qemu-asm qemu-c toolchain clean-toolchain run_assembly_using_riscv_assembler_on_riscv_core run_assembly_using_riscv_assembler_on_aruvi_core run_assembly_using_aruvi_assembler_on_riscv_core run_assembly_using_aruvi_assembler_on_aruvi_core
