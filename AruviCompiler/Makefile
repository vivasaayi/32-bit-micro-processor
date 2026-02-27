CC = gcc
CFLAGS = -Wall -Wextra -std=c99 -g -D_POSIX_C_SOURCE=200809L
TARGET = ccompiler
SOURCES = main.c lexer.c ast.c parser.c type_checker.c codegen.c
OBJECTS = $(SOURCES:.c=.o)

all: $(TARGET)

$(TARGET): $(OBJECTS)
	$(CC) $(CFLAGS) -o $(TARGET) $(OBJECTS)

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	rm -f $(OBJECTS) $(TARGET) *.s

compile_c: $(TARGET)
	./$(TARGET) $(C_SRC) -o output.s

test: $(TARGET)
	./$(TARGET) test_simple.c -o test_simple.s
	cat test_simple.s

.PHONY: all clean test riscv-check compile_c


riscv-check: $(TARGET)
	./check_riscv_compat.sh
