#!/bin/bash
# Mac Graphics Viewer Script for RISC Processor
# Provides easy access to graphics visualization on macOS

set -e

echo "🖼️ Mac Graphics Viewer for RISC Processor"
echo "==========================================="

# Check if matplotlib is available
if ! python3 -c "import matplotlib" 2>/dev/null; then
    echo "⚠️ matplotlib not found. Installing..."
    pip3 install matplotlib
fi

# Parse command line arguments
COMMAND=${1:-"static"}
OPTION=${2:-"color_bars"}

case $COMMAND in
    "demo")
        echo "🎬 Starting animated demo sequence..."
        python3 mac_graphics_viewer.py demo
        ;;
    "static")
        echo "🖼️ Showing static pattern: $OPTION"
        echo "Available patterns: color_bars, checkerboard, gradient, circles, text_demo"
        python3 mac_graphics_viewer.py static "$OPTION"
        ;;
    "analyze")
        VCD_FILE=${OPTION:-"testbench/system_with_display.vcd"}
        echo "🔍 Analyzing VCD file: $VCD_FILE"
        python3 mac_graphics_viewer.py analyze "$VCD_FILE"
        ;;
    "help")
        echo "Usage: $0 [command] [option]"
        echo ""
        echo "Commands:"
        echo "  demo          - Run animated demo sequence"
        echo "  static [type] - Show static pattern (color_bars, checkerboard, gradient, circles, text_demo)"
        echo "  analyze [vcd] - Analyze VCD file for graphics signals"
        echo "  help          - Show this help"
        echo ""
        echo "Examples:"
        echo "  $0 demo"
        echo "  $0 static checkerboard"
        echo "  $0 analyze testbench/system_with_display.vcd"
        ;;
    *)
        echo "⚠️ Unknown command: $COMMAND"
        echo "Use '$0 help' for usage information"
        exit 1
        ;;
esac

echo "✅ Mac Graphics Viewer completed"
