#!/bin/bash

# 32-Bit ASM Test Runner Shell Script
# Comprehensive test runner for 32-bit microprocessor

echo "=== 32-Bit ASM Test Runner ==="
echo "Running all ASM files from examples/ directory"
echo "Temporary files will be stored in temp/ directory"
echo ""

# Make sure we're in the right directory
cd "$(dirname "$0")"

# Check if required tools are available
echo "Checking required tools..."
which python3 > /dev/null || { echo "Error: python3 not found"; exit 1; }
which iverilog > /dev/null || { echo "Error: iverilog not found"; exit 1; }
which vvp > /dev/null || { echo "Error: vvp not found"; exit 1; }
echo "✓ All required tools found"

# Clean up any existing temp directory
echo "Cleaning up previous test results..."
rm -rf temp/

# Check if assembler exists
if [ ! -f "tools/assembler.py" ]; then
    echo "Error: tools/assembler.py not found"
    exit 1
fi

# Check if examples directory exists
if [ ! -d "examples" ]; then
    echo "Error: examples/ directory not found"
    exit 1
fi

# Run the Python test runner
echo ""
echo "Starting 32-bit test suite..."
python3 test_all_asm.py

exit_code=$?

echo ""
echo "=== Test Complete ==="
if [ $exit_code -eq 0 ]; then
    echo "✓ All tests completed successfully"
else
    echo "✗ Some tests failed or encountered errors"
fi

echo ""
echo "Check the temp/ directory for all generated files:"
echo "  - temp/hex/        - Assembled HEX files"
echo "  - temp/testbenches/ - Generated testbenches"
echo "  - temp/vvp/        - Compiled simulation files"
echo "  - temp/vcd/        - Waveform files (view with GTKWave)"
echo "  - temp/reports/    - Simulation logs and summary"
echo ""
echo "To view waveforms: gtkwave temp/vcd/<filename>.vcd"
echo "To see summary: cat temp/reports/test_summary.txt"
echo "To see individual reports: ls temp/reports/"

exit $exit_code
echo ""
echo "To view waveforms: gtkwave temp/vcd/<filename>.vcd"
echo "To view summary: cat temp/reports/test_summary.txt"

if [ $exit_code -eq 0 ]; then
    echo ""
    echo "✓ All tests completed successfully!"
else
    echo ""
    echo "✗ Some tests failed. Check temp/reports/ for details."
fi

exit $exit_code
