#!/bin/bash

# RISC Processor with Java UI Integration Demo
# This script demonstrates how to run your processor simulation
# with the Java UI for real-time framebuffer visualization

set -e

echo "=== RISC Processor + Java UI Integration Demo ==="

# Configuration
TESTBENCH_FILE="processor/testbench/tb_microprocessor_system.v"
VCD_FILE="temp/vcd/tb_microprocessor_system.vcd"
HEX_FILE="examples/simple_test.hex"

# Step 1: Prepare directories
echo "Step 1: Preparing directories..."
mkdir -p temp/reports temp/vcd temp/hex java_ui

# Step 2: Build Java UI (in background)
echo "Step 2: Building Java UI..."
if [ -f "java_ui/FramebufferViewer.java" ]; then
    cd java_ui
    if javac FramebufferViewer.java; then
        echo "✓ Java UI compiled successfully"
        
        # Start Java UI in background
        echo "Starting Java UI in background..."
        java FramebufferViewer &
        JAVA_UI_PID=$!
        echo "Java UI started with PID: $JAVA_UI_PID"
    else
        echo "✗ Java UI compilation failed"
        exit 1
    fi
    cd ..
else
    echo "Warning: Java UI not found. Continuing without GUI..."
fi

# Step 3: Check for processor files
echo "Step 3: Checking processor files..."
if [ ! -f "$TESTBENCH_FILE" ]; then
    echo "Warning: Testbench not found at $TESTBENCH_FILE"
    echo "Using available testbench..."
    TESTBENCH_FILE=$(find . -name "tb_*.v" | head -1)
    if [ -z "$TESTBENCH_FILE" ]; then
        echo "Error: No testbench found"
        exit 1
    fi
fi

# Step 4: Create a test framebuffer program
echo "Step 4: Creating test framebuffer program..."
cat > temp/test_framebuffer.asm << 'EOF'
# Test program that writes to framebuffer
# Base address: 0x10000 (65536)

# Initialize registers
LOADI R1, 65536      # Framebuffer base address
LOADI R2, 0xFF0000   # Red color (RGBA: 0xRRGGBBAA)
LOADI R3, 0          # Pixel counter
LOADI R4, 320        # Width
LOADI R5, 240        # Height
LOADI R6, 76800      # Total pixels (320*240)

loop:
    # Calculate pixel address: base + (pixel_index * 4)
    ADD R7, R1, R3      # R7 = base + pixel_index
    ADD R7, R7, R3      # R7 = base + pixel_index*2
    ADD R7, R7, R3      # R7 = base + pixel_index*3
    ADD R7, R7, R3      # R7 = base + pixel_index*4
    
    # Store pixel color
    STORE R2, R7        # Write color to framebuffer
    
    # Increment pixel counter
    ADDI R3, R3, 1
    
    # Check if done
    CMP R3, R6
    JLT loop
    
    # Change color for next frame
    ADDI R2, R2, 256    # Add to green component
    LOADI R3, 0         # Reset counter
    JMP loop            # Infinite loop

HALT
EOF

# Step 5: Assemble the test program (if assembler exists)
echo "Step 5: Assembling test program..."
if [ -f "tools/assembler.py" ]; then
    python3 tools/assembler.py temp/test_framebuffer.asm temp/test_framebuffer.hex
    HEX_FILE="temp/test_framebuffer.hex"
    echo "✓ Test program assembled"
else
    echo "Warning: Assembler not found. Using existing hex file..."
    if [ ! -f "$HEX_FILE" ]; then
        echo "Creating simple test hex file..."
        cat > temp/simple_framebuffer.hex << 'EOF'
@8000
01000200  // LOADI R1, 65536 (0x10000)
01100100
01A00FF   // LOADI R2, 0xFF0000 (red)
01C0000   // LOADI R3, 0
02000004  // Loop: STORE R2, R1+R3*4
05C0001   // ADDI R3, R3, 1
11C012C0  // CMP R3, 76800
17FFFFC   // JLT loop
1F000000  // HALT
EOF
        HEX_FILE="temp/simple_framebuffer.hex"
    fi
fi

# Step 6: Create enhanced testbench with framebuffer support
echo "Step 6: Creating enhanced testbench..."
cat > temp/tb_with_framebuffer.v << 'EOF'
`timescale 1ns / 1ps

module tb_with_framebuffer;
    reg clk, rst_n;
    wire [31:0] addr_bus, data_bus;
    wire mem_read, mem_write, mem_ready;
    wire halted;
    
    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk; // 100MHz clock
    
    // Memory
    reg [31:0] memory [0:1048575]; // 4MB memory
    reg [31:0] mem_data_out;
    
    // Framebuffer dumper signals
    wire fb_dump_enable = 1'b1;
    wire [31:0] fb_addr;
    wire [31:0] fb_data;
    wire fb_read, fb_ready;
    wire dump_complete;
    
    // CPU instance
    cpu_core cpu (
        .clk(clk), .rst_n(rst_n),
        .addr_bus(addr_bus), .data_bus(data_bus),
        .mem_read(mem_read), .mem_write(mem_write), .mem_ready(mem_ready),
        .halted(halted),
        .interrupt_req(8'h00), .interrupt_ack(),
        .io_addr(), .io_data(), .io_read(), .io_write(),
        .user_mode()
    );
    
    // Display buffer
    display_buffer #(
        .FRAME_WIDTH(320), .FRAME_HEIGHT(240), .BASE_ADDR(32'h10000)
    ) display (
        .clk(clk), .rst_n(rst_n),
        .cpu_addr(addr_bus), .cpu_data(data_bus),
        .cpu_read(mem_read), .cpu_write(mem_write), .cpu_ready(),
        .fb_addr(fb_addr), .fb_data(fb_data),
        .fb_read(fb_read), .fb_ready(fb_ready)
    );
    
    // Framebuffer dumper
    framebuffer_dumper #(
        .FRAME_WIDTH(320), .FRAME_HEIGHT(240), .DUMP_INTERVAL(100000)
    ) dumper (
        .clk(clk), .rst_n(rst_n), .enable(fb_dump_enable),
        .fb_addr(fb_addr), .fb_data(fb_data),
        .fb_read(fb_read), .fb_ready(fb_ready),
        .framebuffer_base_addr(32'h10000), .dump_complete(dump_complete)
    );
    
    // Memory interface
    assign mem_ready = 1'b1;
    assign data_bus = mem_read ? mem_data_out : 32'hZZZZZZZZ;
    
    always @(posedge clk) begin
        if (mem_write && addr_bus < 32'h100000) begin
            memory[addr_bus[19:2]] <= data_bus;
            $display("MEM WRITE: addr=0x%x, data=0x%x", addr_bus, data_bus);
        end
        if (mem_read && addr_bus < 32'h100000) begin
            mem_data_out <= memory[addr_bus[19:2]];
        end
    end
    
    // Load program
    initial begin
        $readmemh("temp/test_framebuffer.hex", memory, 'h2000); // Load at 0x8000
    end
    
    // Test sequence
    initial begin
        $dumpfile("temp/vcd/tb_framebuffer.vcd");
        $dumpvars(0, tb_with_framebuffer);
        
        rst_n = 0;
        #20 rst_n = 1;
        
        $display("Starting framebuffer test...");
        $display("Java UI should show colored output");
        
        // Run for sufficient time to see framebuffer dumps
        #1000000;
        
        if (halted) begin
            $display("CPU halted successfully");
        end else begin
            $display("CPU still running...");
        end
        
        $finish;
    end
    
    // Monitor framebuffer dumps
    always @(posedge dump_complete) begin
        $display("Framebuffer dump completed at time %t", $time);
    end
    
endmodule
EOF

# Step 7: Run simulation with framebuffer
echo "Step 7: Running simulation..."

# Check if we have Icarus Verilog
if command -v iverilog &> /dev/null; then
    echo "Using Icarus Verilog..."
    
    # Compile
    iverilog -I processor/cpu -I processor/io \
             -o temp/tb_framebuffer.vvp \
             temp/tb_with_framebuffer.v \
             processor/cpu/*.v \
             processor/io/framebuffer_dumper.v
    
    echo "Running simulation..."
    vvp temp/tb_framebuffer.vvp
    
    echo "✓ Simulation completed"
    
    if [ -f "temp/vcd/tb_framebuffer.vcd" ]; then
        echo "VCD file generated: temp/vcd/tb_framebuffer.vcd"
    fi
else
    echo "Warning: Icarus Verilog not found. Skipping simulation."
    echo "Install with: brew install icarus-verilog (macOS) or apt-get install iverilog (Linux)"
fi

# Step 8: Create sample framebuffer for testing
echo "Step 8: Creating sample framebuffer for UI testing..."
cat > temp/create_sample_framebuffer.py << 'EOF'
#!/usr/bin/env python3
import os
import time
import random

def create_test_framebuffer():
    """Create a test PPM framebuffer file"""
    width, height = 320, 240
    
    # Create directory if it doesn't exist
    os.makedirs('temp/reports', exist_ok=True)
    
    for frame in range(10):  # Create 10 test frames
        with open('temp/reports/framebuffer.ppm', 'wb') as f:
            # PPM header
            f.write(b'P6\n')
            f.write(f'# Frame {frame}\n'.encode())
            f.write(f'{width} {height}\n'.encode())
            f.write(b'255\n')
            
            # Generate colorful test pattern
            for y in range(height):
                for x in range(width):
                    r = (x + frame * 10) % 256
                    g = (y + frame * 15) % 256
                    b = ((x + y + frame * 5) // 2) % 256
                    f.write(bytes([r, g, b]))
        
        print(f"Generated test frame {frame}")
        time.sleep(1)  # 1 second between frames

if __name__ == '__main__':
    create_test_framebuffer()
EOF

python3 temp/create_sample_framebuffer.py &
SAMPLE_PID=$!

# Step 9: Wait and cleanup
echo "Step 9: Demo running..."
echo ""
echo "=== DEMO STATUS ==="
echo "✓ Java UI should be displaying framebuffer updates"
echo "✓ Sample framebuffer generator is running"
echo "✓ Check temp/reports/framebuffer.ppm for output files"
echo ""
echo "Press Ctrl+C to stop the demo"

# Wait for user input
trap 'echo "Cleaning up..."; kill $JAVA_UI_PID 2>/dev/null; kill $SAMPLE_PID 2>/dev/null; exit 0' INT

# Keep script running
while true; do
    sleep 1
done
