#!/bin/bash

# ASM Test Runner Shell Script
# Simple wrapper for the Python test runner

echo "=== ASM Test Runner ==="
echo "Running all ASM files from examples/ directory"
echo "Temporary files will be stored in temp/ directory"
echo ""

# Make sure we're in the right directory
cd "$(dirname "$0")"

# Run the Python test runner
python3 test_all_asm.py

echo ""
echo "=== Test Complete ==="
echo "Check the temp/ directory for all generated files:"
echo "  - temp/hex/        - Assembled HEX files"
echo "  - temp/testbenches/ - Generated testbenches"
echo "  - temp/vvp/        - Compiled simulation files"
echo "  - temp/vcd/        - Waveform files (view with GTKWave)"
echo "  - temp/reports/    - Simulation logs and summary"
echo ""
echo "To view waveforms: gtkwave temp/vcd/<filename>.vcd"
echo "To see summary: cat temp/reports/summary.txt"
