#!/bin/bash
# Simple test script for the merged toolchain

echo "🚀 Testing HDL Processor Toolchain"
echo "=================================="

# Test C compilation
echo ""
echo "Testing C compilation..."
if ./temp/c_compiler test_programs/c/basic_test.c; then
    echo "✅ C compilation successful"
    # Move the generated file to temp directory
    mv test_programs/c/basic_test.asm temp/basic_test.asm
else
    echo "❌ C compilation failed"
    exit 1
fi

# Test assembly
echo ""
echo "Testing assembly..."
if ./temp/assembler temp/basic_test.asm temp/basic_test.hex; then
    echo "✅ Assembly successful"
else
    echo "❌ Assembly failed" 
    exit 1
fi

# Check output files
echo ""
echo "Checking generated files..."
if [ -f temp/basic_test.asm ]; then
    echo "✅ Assembly file generated"
    wc -l temp/basic_test.asm | awk '{print "   Lines: " $1}'
else
    echo "❌ Assembly file missing"
fi

if [ -f temp/basic_test.hex ]; then
    echo "✅ Hex file generated"
    wc -l temp/basic_test.hex | awk '{print "   Lines: " $1}'
else
    echo "❌ Hex file missing"
fi

echo ""
echo "🎉 Toolchain test completed successfully!"
echo ""
echo "Summary:"
echo "--------"
echo "C Compiler: ✅ Working"
echo "Assembler:  ✅ Working"
echo "Output:     ✅ Generated"
echo ""
echo "You can now compile C programs for the HDL processor using:"
echo "  ./temp/c_compiler test_programs/c/program.c"
echo "  ./temp/assembler temp/program.asm temp/program.hex"
