#!/bin/bash

# Extended Live Console Monitor for RISC Processor
# Provides longer running simulation with more interactive feedback

echo "🖥️  Extended RISC Processor Live Console"
echo "========================================"
echo ""

# Function to format output with enhanced info
format_output_extended() {
    local line_num=1
    local frame_count=0
    while IFS= read -r line; do
        timestamp=$(date '+%H:%M:%S.%3N')
        
        # Count frames and add extra info
        if [[ $line == *"Frame"*"completed"* ]]; then
            ((frame_count++))
            printf "\033[90m%s\033[0m │ \033[32m%2d\033[0m │ \033[93m%s\033[0m \033[96m[Frame #%d]\033[0m\n" "$timestamp" "$line_num" "$line" "$frame_count"
        elif [[ $line == *"System started"* ]]; then
            printf "\033[90m%s\033[0m │ \033[32m%2d\033[0m │ \033[92m%s\033[0m \033[95m[BOOT]\033[0m\n" "$timestamp" "$line_num" "$line"
        elif [[ $line == *"ERROR"* ]] || [[ $line == *"WARNING"* ]]; then
            printf "\033[90m%s\033[0m │ \033[32m%2d\033[0m │ \033[91m%s\033[0m \033[31m[ALERT]\033[0m\n" "$timestamp" "$line_num" "$line"
        elif [[ $line == *"✓"* ]]; then
            printf "\033[90m%s\033[0m │ \033[32m%2d\033[0m │ \033[92m%s\033[0m \033[32m[OK]\033[0m\n" "$timestamp" "$line_num" "$line"
        else
            printf "\033[90m%s\033[0m │ \033[32m%2d\033[0m │ %s\n" "$timestamp" "$line_num" "$line"
        fi
        ((line_num++))
        
        # Add a small delay to make it more visible
        sleep 0.05
    done
    
    echo ""
    echo "\033[96m📊 Simulation Summary:\033[0m"
    echo "  🖼️  Total frames rendered: $frame_count"
    echo "  📝 Total log lines: $((line_num-1))"
    echo "  ⏱️  Monitoring completed at: $(date '+%H:%M:%S')"
}

# Enhanced continuous monitoring
continuous_monitor() {
    echo "🔄 Starting continuous monitoring mode..."
    echo "This will run multiple simulation cycles"
    echo "Press Ctrl+C to stop"
    echo ""
    
    cycle=1
    while true; do
        echo "\033[1m🔁 Simulation Cycle #$cycle\033[0m"
        echo "$(date '+%H:%M:%S') - Starting cycle $cycle..."
        
        ./build_display_system.sh 2>&1 | format_output_extended
        
        echo ""
        echo "\033[93m⏳ Waiting 3 seconds before next cycle...\033[0m"
        sleep 3
        ((cycle++))
        
        if [ $cycle -gt 10 ]; then
            echo "🛑 Reached maximum cycles (10). Stopping."
            break
        fi
    done
}

# Interactive monitoring with user choices
interactive_monitor() {
    echo "🎮 Interactive Monitoring Mode"
    echo "=============================="
    echo ""
    
    while true; do
        echo "Choose an option:"
        echo "1. 🔴 Run single simulation"
        echo "2. 🔄 Run continuous monitoring (10 cycles)"
        echo "3. 📊 Show system status"
        echo "4. 🧹 Clean build files"
        echo "5. 🚪 Exit"
        echo ""
        
        read -p "Enter choice (1-5): " choice
        
        case $choice in
            1)
                echo "🚀 Running single simulation..."
                ./build_display_system.sh 2>&1 | format_output_extended
                ;;
            2)
                continuous_monitor
                ;;
            3)
                echo "📊 System Status:"
                echo "  📁 Build files:"
                ls -la testbench/*.vcd 2>/dev/null | head -3
                echo "  💾 Memory usage:"
                du -h testbench/ 2>/dev/null | tail -1
                echo "  🕒 Last simulation:"
                ls -lt testbench/*.vcd 2>/dev/null | head -1
                ;;
            4)
                echo "🧹 Cleaning build files..."
                rm -f testbench/*.vcd testbench/*.vvp
                echo "✓ Cleaned"
                ;;
            5)
                echo "👋 Goodbye!"
                exit 0
                ;;
            *)
                echo "❌ Invalid choice"
                ;;
        esac
        echo ""
    done
}

# Main script logic
if [ "$1" == "live" ]; then
    echo "🔴 Starting enhanced live simulation monitoring..."
    echo "Press Ctrl+C to stop"
    echo ""
    
    ./build_display_system.sh 2>&1 | format_output_extended
    
elif [ "$1" == "continuous" ]; then
    continuous_monitor
    
elif [ "$1" == "interactive" ]; then
    interactive_monitor
    
elif [ "$1" == "tail" ]; then
    echo "📊 Monitoring simulation log file..."
    echo "Press Ctrl+C to stop"
    echo ""
    
    # Create log file if it doesn't exist
    touch simulation.log
    tail -f simulation.log | format_output_extended
    
else
    echo "🖥️  Extended RISC Processor Live Console"
    echo "========================================"
    echo ""
    echo "Available modes:"
    echo "  ./live_console_extended.sh live        - Single simulation with enhanced output"
    echo "  ./live_console_extended.sh continuous  - Multiple simulation cycles"
    echo "  ./live_console_extended.sh interactive - Interactive menu mode"
    echo "  ./live_console_extended.sh tail        - Monitor log file"
    echo ""
    echo "🎮 Starting demo mode with enhanced formatting..."
    echo ""
    
    # Demo with enhanced formatting
    demo_lines=(
        "RISC Processor Enhanced Console v2.0"
        "System startup sequence initiated..."
        "✓ CPU Core: 32-bit RISC-V architecture loaded"
        "✓ Memory: 64KB RAM + 32KB ROM initialized" 
        "✓ Display: VGA 640x480 @ 60Hz controller ready"
        "✓ I/O: UART, Timer, Interrupt systems online"
        ""
        "Loading advanced display demo program..."
        "Program size: 256 instructions, 1.2KB binary"
        "Starting execution with enhanced monitoring..."
        ""
        "Frame           0 completed"
        "Frame           1 completed"
        "Frame           2 completed"
        "System started: CPU and display active"
        "> Display Mode: High-resolution text (80x25)"
        "> Console output: Full color support enabled"
        "> Graphics mode: Pixel-perfect rendering active"
        ""
        "Running advanced graphics test sequence..."
        "> Drawing geometric patterns..."
        "> Rendering text overlays..."
        "Frame           3 completed"
        "Frame           4 completed"
        "> Color palette: 256-color mode engaged"
        "> Memory bandwidth: Optimal performance"
        ""
        "✓ All systems operational - ready for user interaction"
        "> Console prompt active: Type commands..."
        "> Graphics buffer: Ready for drawing operations"
        "> System status: All green - 100% operational"
    )
    
    echo "${demo_lines[@]}" | tr ' ' '\n' | format_output_extended
    
    echo ""
    echo "Demo complete. Use specific modes for live monitoring:"
    echo "  ./live_console_extended.sh live"
    echo "  ./live_console_extended.sh interactive"
fi
