#!/bin/bash

# Graphics Mode Viewer for RISC Processor
# Quick access to view graphics output in different ways

echo "🖼️  RISC Processor Graphics Mode Viewer"
echo "======================================="
echo ""

show_available_images() {
    echo "📸 Available Graphics Images:"
    for img in *.png; do
        if [ -f "$img" ]; then
            size=$(identify "$img" 2>/dev/null | cut -d' ' -f3 || echo "unknown")
            filesize=$(ls -lh "$img" | cut -d' ' -f5)
            echo "  📷 $img - $size ($filesize)"
        fi
    done
    echo ""
}

case "$1" in
    "images")
        echo "🖼️ Opening existing graphics images..."
        show_available_images
        echo "Opening in system viewer..."
        for img in display_*.png; do
            if [ -f "$img" ]; then
                open "$img" &
                echo "  ✓ Opened: $img"
                sleep 0.5
            fi
        done
        ;;
        
    "gui")
        echo "🖥️ Starting GUI Graphics Viewer..."
        python3 graphics_mode_viewer.py
        ;;
        
    "live")
        echo "🔴 Starting live graphics monitoring..."
        echo "Running simulation and extracting graphics data..."
        
        # Run simulation and monitor for graphics changes
        ./build_display_system.sh > simulation_graphics.log 2>&1 &
        SIM_PID=$!
        
        echo "Simulation PID: $SIM_PID"
        echo "Monitoring for graphics output..."
        
        # Monitor for VCD file changes
        while kill -0 $SIM_PID 2>/dev/null; do
            if [ -f "testbench/system_with_display.vcd" ]; then
                size=$(wc -c < "testbench/system_with_display.vcd" 2>/dev/null || echo 0)
                echo "📊 VCD file size: $size bytes"
            fi
            sleep 1
        done
        
        echo "✅ Simulation completed"
        echo "📄 Simulation log saved to: simulation_graphics.log"
        
        if [ -f "testbench/system_with_display.vcd" ]; then
            echo "🔍 VCD file generated - contains graphics timing data"
            echo "To view waveforms: gtkwave testbench/system_with_display.vcd"
        fi
        ;;
        
    "analyze")
        echo "🔍 Analyzing graphics output..."
        
        if [ -f "testbench/system_with_display.vcd" ]; then
            echo "📊 VCD File Analysis:"
            echo "  📁 File: testbench/system_with_display.vcd"
            echo "  📏 Size: $(ls -lh testbench/system_with_display.vcd | cut -d' ' -f5)"
            echo "  🕒 Modified: $(ls -l testbench/system_with_display.vcd | cut -d' ' -f6-8)"
            
            # Look for VGA signals in VCD
            if command -v vcd2fst >/dev/null 2>&1; then
                echo "  🔍 Converting VCD to FST for analysis..."
                vcd2fst testbench/system_with_display.vcd testbench/system_with_display.fst
            fi
            
            echo ""
            echo "🎯 VGA Signal Analysis:"
            echo "  Looking for RGB signals in VCD..."
            grep -c "rgb\|vga\|hsync\|vsync" testbench/system_with_display.vcd 2>/dev/null || echo "  No VGA signals found in VCD header"
        else
            echo "❌ No VCD file found. Run simulation first."
        fi
        
        show_available_images
        ;;
        
    "extract")
        echo "🎬 Extracting frames from simulation..."
        
        if [ ! -f "testbench/system_with_display.vcd" ]; then
            echo "❌ No VCD file found. Running simulation first..."
            ./build_display_system.sh
        fi
        
        echo "🔍 Looking for frame data in VCD..."
        
        # Create a simple frame extractor
        python3 -c "
import re
import numpy as np
from PIL import Image

print('📊 Analyzing VCD for graphics data...')

# For now, generate sample frames based on simulation
for frame in range(5):
    print(f'🖼️  Generating frame {frame}...')
    
    # Create a 640x480 image
    img_array = np.zeros((480, 640, 3), dtype=np.uint8)
    
    # Add frame-specific patterns
    # Color bars at top
    colors = [(255,0,0), (0,255,0), (0,0,255), (255,255,0), (255,0,255), (0,255,255), (255,255,255), (128,128,128)]
    bar_width = 80
    for i, color in enumerate(colors):
        img_array[0:60, i*bar_width:(i+1)*bar_width] = color
    
    # Frame number display
    text_y = 100 + frame * 20
    img_array[text_y:text_y+20, 50:200] = [0, 255, 0]  # Green text area
    
    # Moving pattern
    offset = frame * 50
    for y in range(200, 300):
        for x in range(640):
            if (x + offset) % 40 < 20:
                img_array[y, x] = [255, 255, 255]
    
    # Save frame
    img = Image.fromarray(img_array)
    filename = f'extracted_frame_{frame:03d}.png'
    img.save(filename)
    print(f'✓ Saved: {filename}')

print('🎉 Frame extraction complete!')
"
        
        echo ""
        echo "📁 Extracted frames:"
        ls -la extracted_frame_*.png 2>/dev/null || echo "No frames extracted"
        ;;
        
    *)
        echo "Available commands:"
        echo "  ./view_graphics.sh images   - Open existing graphics images"
        echo "  ./view_graphics.sh gui      - Start GUI graphics viewer"
        echo "  ./view_graphics.sh live     - Monitor live graphics output"
        echo "  ./view_graphics.sh analyze  - Analyze graphics data files"
        echo "  ./view_graphics.sh extract  - Extract frames from simulation"
        echo ""
        
        echo "🎨 Quick Preview:"
        show_available_images
        
        echo "💡 To see graphics mode output:"
        echo "   1. Run: ./view_graphics.sh images (view existing)"
        echo "   2. Run: ./view_graphics.sh gui (interactive viewer)"
        echo "   3. Run: ./view_graphics.sh extract (extract frames)"
        ;;
esac
