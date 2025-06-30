#!/bin/bash

echo "=== Building Complete Display System ==="

# Compile with iverilog if available
if command -v iverilog >/dev/null 2>&1; then
    echo "Compiling system with iverilog..."
    
    cd testbench
    iverilog -o tb_system_with_display \
        tb_system_with_display.v \
        ../microprocessor_system_with_display.v \
        ../io/display_controller.v
    
    if [ $? -eq 0 ]; then
        echo "✓ Compilation successful"
        
        echo "Running simulation..."
        ./tb_system_with_display
        
        if [ $? -eq 0 ]; then
            echo "✓ Simulation completed successfully"
            echo "VCD file: system_with_display.vcd"
        else
            echo "⚠ Simulation completed with warnings"
        fi
    else
        echo "✗ Compilation failed"
    fi
    
    cd ..
else
    echo "iverilog not available - skipping simulation"
fi

echo ""
echo "=== System Files Created ==="
echo "Enhanced system: microprocessor_system_with_display.v"
echo "Test bench: testbench/tb_system_with_display.v"
echo "Display controller: io/display_controller.v"
echo "Demo program: output/simple_display_demo.hex"
echo ""
echo "To view simulation results:"
echo "  gtkwave testbench/system_with_display.vcd"
