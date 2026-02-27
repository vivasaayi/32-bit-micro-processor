# Makefile for AruviAsm Assembler
# Builds the assembler for the AruviCore processor

CC = gcc
CFLAGS = -Wall -Wextra -std=c99 -O2 -g
TARGET = assembler
SOURCE = assembler.c

# Phony targets
.PHONY: all clean test help

# Default target
all: $(TARGET)
	@echo "✓ AruviAsm built successfully"
	@echo "  - Assembler: $(TARGET)"

# Build assembler
$(TARGET): $(SOURCE)
	@echo "Building assembler..."
	$(CC) $(CFLAGS) -o $(TARGET) $(SOURCE)

clean:
	rm -f $(TARGET) *.o

test: $(TARGET)
	@echo "Testing assembler..."
	# Add test commands here if needed

help:
	@echo "AruviAsm Makefile"
	@echo "Targets:"
	@echo "  all    - Build the assembler (default)"
	@echo "  clean  - Remove built files"
	@echo "  test   - Run tests (placeholder)"
	@echo "  help   - Show this help"