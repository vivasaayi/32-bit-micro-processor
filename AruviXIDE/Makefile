JAVA_SRC_DIR = src
BUILD_DIR = build
MAIN_CLASS = main.CpuIDE

# Find all Java source files
JAVA_FILES := $(shell find $(JAVA_SRC_DIR) -name "*.java")

.PHONY: all clean compile run

all: compile

compile:
	@echo "Creating build directory..."
	@mkdir -p $(BUILD_DIR)
	@echo "Compiling Java sources..."
	@find $(JAVA_SRC_DIR) -name "*.java" > sources.txt
	javac -d $(BUILD_DIR) -cp $(BUILD_DIR) @sources.txt
	@rm sources.txt
	@echo "Compilation complete!"

run: compile
	@echo "Running application..."
	cd $(BUILD_DIR) && java $(MAIN_CLASS)

clean:
	@echo "Cleaning build directory..."
	@rm -rf $(BUILD_DIR)
	@rm -f sources.txt

install-deps:
	@echo "No external dependencies required for basic Swing application"
