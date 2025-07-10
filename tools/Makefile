# Makefile for HDL Processor Tools
# Builds the complete toolchain for custom 32-bit RISC processor

CC = gcc
CFLAGS = -Wall -Wextra -std=c99 -O2 -g
TEMP_DIR = ../temp
ASSEMBLER_TARGET = $(TEMP_DIR)/assembler
ASSEMBLER_SOURCE = assembler.c

# Phony targets
.PHONY: all clean test test-compiler test-assembler help install

# Default target
all: $(ASSEMBLER_TARGET)
	@echo "✓ All tools built successfully"
	@echo "  - Assembler: $(ASSEMBLER_TARGET)"

# Build assembler
$(ASSEMBLER_TARGET): $(ASSEMBLER_SOURCE)
	@echo "Building assembler..."
	@mkdir -p $(TEMP_DIR)
	$(CC) $(CFLAGS) -o $(ASSEMBLER_TARGET) $(ASSEMBLER_SOURCE)

# Build C compiler  
$(COMPILER_TARGET): $(COMPILER_SOURCE)
	@echo "Building C compiler..."
	@mkdir -p $(TEMP_DIR)
	$(CC) $(CFLAGS) -o $(COMPILER_TARGET) $(COMPILER_SOURCE)

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	rm -f $(ASSEMBLER_TARGET) $(COMPILER_TARGET)
	rm -f $(TEMP_DIR)/test.*
	rm -rf $(TEMP_DIR)/test_*

# Test assembler
test-assembler: $(ASSEMBLER_TARGET)
	@echo "Testing assembler..."
	@echo "LOADI R1, #42" > $(TEMP_DIR)/test.asm
	@echo "LOADI R2, #10" >> $(TEMP_DIR)/test.asm
	@echo "ADD R3, R1, R2" >> $(TEMP_DIR)/test.asm
	@echo "HALT" >> $(TEMP_DIR)/test.asm
	$(ASSEMBLER_TARGET) $(TEMP_DIR)/test.asm $(TEMP_DIR)/test.hex
	@echo "✓ Assembler test completed"
	@rm -f $(TEMP_DIR)/test.asm $(TEMP_DIR)/test.hex

# Test both tools
test: test-assembler test-compiler
	@echo "✓ All tests passed"

# Install tools to system PATH (optional)
install: all
	@echo "Installing tools to /usr/local/bin..."
	@sudo cp $(ASSEMBLER_TARGET) /usr/local/bin/custom32-assembler
	@sudo cp $(COMPILER_TARGET) /usr/local/bin/custom32-compiler
	@echo "✓ Tools installed"

# Help target
help:
	@echo "HDL Processor Toolchain"
	@echo "======================="
	@echo ""
	@echo "Available targets:"
	@echo "  all           - Build all tools (default)"
	@echo "  assembler     - Build assembler only"
	@echo "  c_compiler    - Build C compiler only"
	@echo "  clean         - Remove build artifacts"
	@echo "  test          - Test both tools"
	@echo "  test-assembler- Test assembler only"
	@echo "  test-compiler - Test C compiler only" 
	@echo "  install       - Install tools to system PATH"
	@echo "  help          - Show this help"
	@echo ""
	@echo "Usage examples:"
	@echo "  make                    # Build everything"
	@echo "  make test               # Run all tests"
	@echo "  $(COMPILER_TARGET) prog.c  # Compile C to assembly"
	@echo "  $(ASSEMBLER_TARGET) prog.asm prog.hex  # Assemble to hex"
