#!/bin/bash

# Build script for Java UI
cd "$(dirname "$0")"

# Create build directory
mkdir -p build

# Compile all Java files
echo "Compiling Java files..."
find src -name "*.java" -type f > sources.txt
javac -d build -cp build @sources.txt

if [ $? -eq 0 ]; then
    echo "Compilation successful!"
    echo "Running the application..."
    cd build
    java main.CpuIDE
else
    echo "Compilation failed!"
    exit 1
fi
