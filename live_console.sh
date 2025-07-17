#!/bin/bash

# Simple Live Console Monitor for RISC Processor
# Shows real-time simulation output in a formatted way

echo "🖥️  RISC Processor Live Console"
echo "================================"
echo ""

# Function to format output
format_output() {
    local line_num=1
    while IFS= read -r line; do
        timestamp=$(date '+%H:%M:%S')
        printf "\033[90m%s\033[0m │ \033[32m%2d\033[0m │ %s\n" "$timestamp" "$line_num" "$line"
        ((line_num++))
    done
}

# Option 1: Monitor live simulation
if [ "$1" == "live" ]; then
    echo "🔴 Starting live simulation monitoring..."
    echo "Press Ctrl+C to stop"
    echo ""
    
    # Run simulation and pipe output through formatter
    ./build_display_system.sh 2>&1 | format_output
    
# Option 2: Monitor existing simulation output
elif [ "$1" == "tail" ]; then
    echo "📊 Monitoring simulation log file..."
    echo "Press Ctrl+C to stop"
    echo ""
    
    # Create log file if it doesn't exist
    touch simulation.log
    tail -f simulation.log | format_output
    
# Option 3: Interactive demo
else
    echo "Available options:"
    echo "  ./live_console.sh live  - Monitor live simulation"
    echo "  ./live_console.sh tail  - Monitor log file"
    echo ""
    echo "🎮 Starting interactive demo mode..."
    echo ""
    
    # Demo output
    demo_lines=(
        "RISC Processor System Boot"
        "Hardware initialization..."
        "✓ CPU Core: 32-bit RISC-V compatible"
        "✓ Memory: 64KB RAM + 32KB ROM" 
        "✓ Display: VGA 640x480 @ 60Hz"
        "✓ I/O: UART, Timer, Interrupt Controller"
        ""
        "Loading display demo program..."
        "Program loaded: 127 instructions"
        "Starting execution..."
        ""
        "Display Mode: Text (80x25)"
        "> Hello from RISC Processor!"
        "> Console ready for input"
        "> Type 'help' for commands"
        ""
        "Switching to graphics mode..."
        "Drawing test pattern..."
        "Frame buffer updated"
        ""
        "System ready - waiting for user input..."
        "> _"
    )
    
    line_num=1
    for line in "${demo_lines[@]}"; do
        timestamp=$(date '+%H:%M:%S')
        printf "\033[90m%s\033[0m │ \033[32m%2d\033[0m │ %s\n" "$timestamp" "$line_num" "$line"
        ((line_num++))
        sleep 0.8
    done
    
    echo ""
    echo "Demo complete. Use 'live' or 'tail' options for real monitoring."
fi
