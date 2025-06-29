#!/bin/bash

# Build JVM with enhanced assembler workflow
# This script uses the enhanced assembler where possible, 
# falls back to conversion for compatibility

set -e

echo "=== Enhanced JVM Build Workflow ==="

# Step 1: Compile JVM C code
echo "Step 1: Compiling JVM C code..."
cd /Users/rajanpanneerselvam/work/hdl/compiler
if ! ./ccompiler ../jvm/minimal_jvm.c ../output/jvm_output.s; then
    echo "Failed to compile JVM"
    exit 1
fi

# Step 2: Try enhanced assembler first
echo "Step 2: Trying enhanced assembler..."
cd /Users/rajanpanneerselvam/work/hdl
if ./tools/enhanced_assembler output/jvm_output.s output/jvm_direct.hex 2>/dev/null; then
    echo "✓ Enhanced assembler succeeded!"
    JVM_HEX="output/jvm_direct.hex"
else
    echo "Enhanced assembler failed, falling back to conversion..."
    
    # Step 2b: Convert assembly format
    echo "Step 2b: Converting assembly format..."
    if ! python3 tools/convert_minimal_assembly.py output/jvm_output.s output/jvm_converted.asm; then
        echo "Failed to convert assembly"
        exit 1
    fi
    
    # Step 2c: Assemble with original assembler
    echo "Step 2c: Assembling with original assembler..."
    if ! ./tools/assembler output/jvm_converted.asm output/jvm_converted.hex; then
        echo "Failed to assemble JVM"
        exit 1
    fi
    JVM_HEX="output/jvm_converted.hex"
fi

echo "✓ JVM assembled successfully: $JVM_HEX"

# Step 3: Test minimal C program
echo "Step 3: Testing minimal C program..."
cd /Users/rajanpanneerselvam/work/hdl/compiler
if ! ./ccompiler ../jvm/minimal_test.c ../output/minimal_test.s; then
    echo "Failed to compile minimal test"
    exit 1
fi

cd /Users/rajanpanneerselvam/work/hdl
if ./tools/enhanced_assembler output/minimal_test.s output/minimal_test_direct.hex 2>/dev/null; then
    echo "✓ Enhanced assembler succeeded for minimal test!"
    TEST_HEX="output/minimal_test_direct.hex"
else
    echo "Enhanced assembler failed for minimal test, using conversion..."
    if ! python3 tools/convert_minimal_assembly.py output/minimal_test.s output/minimal_test.asm; then
        echo "Failed to convert minimal test assembly"
        exit 1
    fi
    
    if ! ./tools/assembler output/minimal_test.asm output/minimal_test.hex; then
        echo "Failed to assemble minimal test"
        exit 1
    fi
    TEST_HEX="output/minimal_test.hex"
fi

echo "✓ Minimal test assembled successfully: $TEST_HEX"

# Step 4: Create test bench for JVM
echo "Step 4: Creating JVM test bench..."
cat > testbench/tb_jvm_test.v << 'EOF'
`timescale 1ns / 1ps

module tb_jvm_test;

    // Testbench signals
    reg clk;
    reg reset;
    reg [31:0] instruction_memory [0:65535];
    reg [31:0] data_memory [0:65535];
    
    // CPU instance
    cpu_core cpu (
        .clk(clk),
        .reset(reset)
    );
    
    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    // Test sequence
    initial begin
        $display("=== JVM Test Bench ===");
        
        // Load JVM hex file
        $readmemh("../output/jvm_direct.hex", instruction_memory);
        
        // Initialize
        reset = 1;
        #20;
        reset = 0;
        
        // Run for a reasonable amount of time
        #10000;
        
        $display("JVM test completed");
        $finish;
    end
    
    // Monitor important signals
    always @(posedge clk) begin
        if (!reset) begin
            $display("Time: %0t, PC: %h", $time, cpu.pc);
        end
    end

endmodule
EOF

echo "✓ JVM test bench created"

# Step 5: Summary
echo ""
echo "=== Build Summary ==="
echo "JVM hex file: $JVM_HEX"
echo "Test hex file: $TEST_HEX"
echo "JVM test bench: testbench/tb_jvm_test.v"
echo ""
echo "Next steps:"
echo "1. Run: cd testbench && iverilog -o tb_jvm_test tb_jvm_test.v ../cpu/*.v"
echo "2. Run: ./tb_jvm_test"
echo "3. View: gtkwave tb_jvm_test.vcd"
echo ""
echo "✓ Enhanced JVM build workflow completed!"
