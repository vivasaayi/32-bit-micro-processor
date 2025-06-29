#!/bin/bash

# JVM Build Script - Compile JVM for RISC Processor
# This script compiles the minimal JVM and prepares it for execution

echo "🏗️  BUILDING MINIMAL JVM FOR RISC PROCESSOR"
echo "============================================"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Directories
COMPILER_DIR="compiler"
JVM_DIR="jvm"
TOOLS_DIR="tools"
OUTPUT_DIR="output"

# Create output directory
mkdir -p $OUTPUT_DIR

echo -e "${BLUE}📁 Setting up build environment...${NC}"

# Step 1: Build the C compiler if needed
if [ ! -f "$COMPILER_DIR/ccompiler" ]; then
    echo -e "${YELLOW}⚙️  Building C compiler...${NC}"
    cd $COMPILER_DIR
    make clean && make
    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ Failed to build C compiler${NC}"
        exit 1
    fi
    cd ..
    echo -e "${GREEN}✅ C compiler built successfully${NC}"
else
    echo -e "${GREEN}✅ C compiler ready${NC}"
fi

# Step 2: Compile the JVM
echo -e "${BLUE}🔨 Compiling JVM...${NC}"
cd $COMPILER_DIR
./ccompiler ../jvm/operational_jvm.c -o ../output/jvm_output.s
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Failed to compile JVM${NC}"
    exit 1
fi
cd ..
echo -e "${GREEN}✅ JVM compiled to assembly${NC}"

# Step 3: Build assembler tools if needed
echo -e "${BLUE}🔧 Preparing assembler tools...${NC}"
cd $TOOLS_DIR
make
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Failed to build assembler tools${NC}"
    exit 1
fi
cd ..
echo -e "${GREEN}✅ Assembler tools ready${NC}"

# Step 4: Convert assembly syntax
echo -e "${BLUE}🔄 Converting assembly syntax...${NC}"
python3 tools/convert_assembly.py output/jvm_output.s output/jvm_converted.asm
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Failed to convert assembly syntax${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Assembly syntax converted${NC}"

# Step 5: Assemble to machine code
echo -e "${BLUE}⚡ Assembling to machine code...${NC}"
cd $TOOLS_DIR
./assembler ../output/jvm_converted.asm ../output/jvm.hex
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Failed to assemble JVM${NC}"
    exit 1
fi
cd ..
echo -e "${GREEN}✅ JVM assembled to machine code${NC}"

# Step 6: Verify output files
if [ -f "output/jvm.hex" ]; then
    echo -e "${GREEN}✅ JVM hex file created: output/jvm.hex${NC}"
    echo -e "${BLUE}📊 File size: $(wc -c < output/jvm.hex) bytes${NC}"
else
    echo -e "${RED}❌ JVM hex file not created${NC}"
    exit 1
fi

echo -e "${GREEN}🎉 JVM BUILD COMPLETED SUCCESSFULLY!${NC}"
echo -e "${BLUE}📄 Output files:${NC}"
echo -e "   - Assembly: output/jvm_output.s"
echo -e "   - Converted: output/jvm_converted.asm"
echo -e "   - Machine code: output/jvm.hex"
echo
echo -e "${YELLOW}📋 Next steps:${NC}"
echo -e "   1. Use 'run_jvm_test.sh' to test JVM with embedded programs"
echo -e "   2. Use 'run_java_program.sh <program>' to run Java programs"
echo
