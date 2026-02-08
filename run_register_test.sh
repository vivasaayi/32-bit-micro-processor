#!/bin/bash

# Test Bench Runner for Register File
# This script compiles and runs the register file test bench

echo "=== Register File Test Bench Runner ==="
echo "Compiling Verilog files..."

# Compile the test bench and DUT
iverilog -o tb_register_file \
    processor/testbench/tb_register_file.v \
    processor/cpu/register_file.v

if [ $? -ne 0 ]; then
    echo "❌ Compilation failed!"
    exit 1
fi

echo "✅ Compilation successful."
echo "Running simulation..."
echo ""

# Run the simulation
vvp tb_register_file

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Test bench completed successfully!"
else
    echo ""
    echo "❌ Test bench failed!"
    exit 1
fi