#!/bin/bash
# Script to compile, assemble, and prepare a C program for loading onto PYNQ-Z2 FPGA
# Target: /test_programs/c/1_basic_test.c
# Assumes Vivado/SDK bitstream and memory map are already set up for your design

set -e

HDL_ROOT="$(pwd)"
C_SRC="test_programs/c/1_basic_test.c"
PREPROCESSED_C="temp/c_generated_asm/1_basic_test_preprocessed.c"
MEM_LAYOUT_JSON="temp/c_generated_asm/1_basic_test_memory_layout.json"
ASM_FILE="temp/c_generated_asm/1_basic_test_preprocessed.asm"
ENHANCED_ASM="temp/c_generated_asm/1_basic_test_enhanced.asm"
HEX_FILE="temp/c_generated_hex/1_basic_test_enhanced.hex"

# 1. Preprocess C for enhanced logging (optional, but recommended)
echo "[1/5] Preprocessing C for enhanced logging..."
python3 tools/enhanced_string_preprocessor.py "$C_SRC" "$PREPROCESSED_C" "$MEM_LAYOUT_JSON"

# 2. Compile C to Assembly
echo "[2/5] Compiling C to Assembly..."
./temp/c_compiler "$PREPROCESSED_C"

# 3. Enhanced memory write postprocessing (optional, but recommended)
echo "[3/5] Postprocessing Assembly for memory writes..."
python3 tools/enhanced_memory_writes.py "$ASM_FILE" "$ENHANCED_ASM" "$MEM_LAYOUT_JSON"

# 4. Assemble to HEX
echo "[4/5] Assembling to HEX..."
./temp/assembler "$ENHANCED_ASM" "$HEX_FILE"

# 5. Copy HEX to PYNQ-Z2 SD card or project directory
echo "[5/5] Copying HEX file to PYNQ-Z2 project directory..."
# Example: scp or cp to your PYNQ overlay/memory init location
# Replace the following line with your actual path or scp command
cp "$HEX_FILE" /path/to/your/pynq/bitstream/project/1_basic_test_enhanced.hex

echo "\nAll steps complete!"
echo "- HEX file ready: $HEX_FILE"
echo "- Load this HEX file into your PYNQ-Z2 memory using $readmemh in your Verilog"
echo "- Re-synthesize and program the FPGA if needed."

echo "\nExample Verilog snippet:"
echo '  initial begin'
echo '    $readmemh("1_basic_test_enhanced.hex", memory_array, 8192); // 0x8000 offset if needed'
echo '  end'
