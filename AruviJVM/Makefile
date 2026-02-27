# AruviJVM Makefile
# Simple makefile for compiling the Java bytecode interpreter

CC = gcc
CFLAGS = -Wall -Wextra -std=c99 -O2 -g
SRCDIR = src
OBJDIR = obj
BINDIR = bin

# Source files
SOURCES = $(wildcard $(SRCDIR)/*.c)
OBJECTS = $(SOURCES:$(SRCDIR)/%.c=$(OBJDIR)/%.o)
TARGET = $(BINDIR)/aruvijvm

# Default target
all: $(TARGET)

# Create directories if they don't exist
$(OBJDIR):
	mkdir -p $(OBJDIR)

$(BINDIR):
	mkdir -p $(BINDIR)

# Build target
$(TARGET): $(OBJECTS) | $(BINDIR)
	$(CC) $(OBJECTS) -o $@
	@echo "Build complete! Run with: make run"

# Compile source files
$(OBJDIR)/%.o: $(SRCDIR)/%.c | $(OBJDIR)
	$(CC) $(CFLAGS) -c $< -o $@

# Run the interpreter
run: $(TARGET)
	@echo "Running AruviJVM tests..."
	./$(TARGET)

# Test compilation with different warning levels
test-compile: CFLAGS += -Wpedantic -Wextra -Werror
test-compile: clean $(TARGET)
	@echo "Strict compilation test passed!"

# Clean build files
clean:
	rm -rf $(OBJDIR) $(BINDIR)

# Install (copy to /usr/local/bin)
install: $(TARGET)
	sudo cp $(TARGET) /usr/local/bin/

# For cross-compilation to RISC-V (when riscv64-linux-gnu-gcc is available)
riscv: CC = riscv64-linux-gnu-gcc
riscv: CFLAGS = -Wall -Wextra -std=c99 -O2 -static
riscv: TARGET = $(BINDIR)/aruvijvm-riscv
riscv: $(TARGET)

# Help
help:
	@echo "AruviJVM Build System"
	@echo "====================="
	@echo "Available targets:"
	@echo "  all      - Build the interpreter (default)"
	@echo "  run      - Build and run the interpreter"
	@echo "  clean    - Remove build files"
	@echo "  install  - Install to /usr/local/bin"
	@echo "  riscv    - Cross-compile for RISC-V"
	@echo "  help     - Show this help message"

.PHONY: all run clean install riscv help
