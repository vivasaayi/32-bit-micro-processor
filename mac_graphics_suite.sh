#!/bin/bash
# Comprehensive Mac Graphics Suite for RISC Processor
# All-in-one graphics visualization and testing for macOS

set -e

echo "🖼️ Mac Graphics Suite for RISC Processor"
echo "=========================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to check and install dependencies
check_dependencies() {
    echo -e "${BLUE}🔍 Checking dependencies...${NC}"
    
    # Check Python 3
    if ! command -v python3 &> /dev/null; then
        echo -e "${RED}⚠️ Python 3 not found${NC}"
        exit 1
    fi
    
    # Check matplotlib
    if ! python3 -c "import matplotlib" 2>/dev/null; then
        echo -e "${YELLOW}📦 Installing matplotlib...${NC}"
        pip3 install matplotlib
    fi
    
    # Check PIL/Pillow
    if ! python3 -c "import PIL" 2>/dev/null; then
        echo -e "${YELLOW}📦 Installing Pillow...${NC}"
        pip3 install Pillow
    fi
    
    echo -e "${GREEN}✅ All dependencies ready${NC}"
}

# Function to show help
show_help() {
    echo "Usage: $0 [command] [options]"
    echo ""
    echo -e "${CYAN}Available Commands:${NC}"
    echo "  png [pattern]     - Generate PNG images"
    echo "  view [pattern]    - View graphics patterns interactively"
    echo "  demo              - Run animated demo sequence"
    echo "  analyze [vcd]     - Analyze VCD file for graphics signals"
    echo "  gallery           - Open all generated images"
    echo "  clean             - Clean up generated files"
    echo "  test              - Run graphics system test"
    echo "  help              - Show this help"
    echo ""
    echo -e "${CYAN}Pattern Types:${NC}"
    echo "  color_bars        - Vertical color bars"
    echo "  checkerboard      - Black and white checkerboard"
    echo "  gradient          - Color gradient pattern"
    echo "  circles           - Colored circles pattern"
    echo "  test_pattern      - Comprehensive test pattern"
    echo "  text_demo         - Text display demonstration"
    echo "  all               - Generate/view all patterns"
    echo ""
    echo -e "${CYAN}Examples:${NC}"
    echo "  $0 png all                    # Generate all PNG patterns"
    echo "  $0 view checkerboard          # View checkerboard pattern"
    echo "  $0 demo                       # Run animated demo"
    echo "  $0 analyze testbench/system_with_display.vcd"
    echo "  $0 gallery                    # Open all images"
}

# Function to generate PNG images
generate_png() {
    local pattern=${1:-"all"}
    echo -e "${BLUE}🖼️ Generating PNG graphics: $pattern${NC}"
    python3 png_graphics_generator.py "$pattern"
    
    if [ "$pattern" = "all" ]; then
        echo -e "${GREEN}📁 Opening image gallery...${NC}"
        open graphics_*.png
    else
        latest_file=$(ls -t graphics_${pattern}_*.png 2>/dev/null | head -1)
        if [ -n "$latest_file" ]; then
            echo -e "${GREEN}🖼️ Opening: $latest_file${NC}"
            open "$latest_file"
        fi
    fi
}

# Function to view graphics interactively
view_graphics() {
    local pattern=${1:-"color_bars"}
    echo -e "${BLUE}👁️ Starting interactive graphics viewer: $pattern${NC}"
    python3 mac_graphics_viewer.py static "$pattern" &
    
    # Give viewer time to start
    sleep 2
    echo -e "${YELLOW}💡 Close the matplotlib window to continue${NC}"
}

# Function to run demo
run_demo() {
    echo -e "${PURPLE}🎬 Starting animated graphics demo...${NC}"
    python3 mac_graphics_viewer.py demo
}

# Function to analyze VCD files
analyze_vcd() {
    local vcd_file=${1:-"testbench/system_with_display.vcd"}
    echo -e "${BLUE}🔍 Analyzing VCD file: $vcd_file${NC}"
    
    if [ ! -f "$vcd_file" ]; then
        echo -e "${YELLOW}⚠️ VCD file not found: $vcd_file${NC}"
        echo "Attempting to build system and run simulation..."
        
        if [ -f "build_display_system.sh" ]; then
            ./build_display_system.sh
        else
            echo -e "${RED}❌ No build script found${NC}"
            return 1
        fi
    fi
    
    python3 mac_graphics_viewer.py analyze "$vcd_file"
}

# Function to open gallery
open_gallery() {
    echo -e "${BLUE}🖼️ Opening graphics gallery...${NC}"
    
    png_count=$(ls graphics_*.png 2>/dev/null | wc -l)
    if [ "$png_count" -eq 0 ]; then
        echo -e "${YELLOW}📷 No PNG files found. Generating all patterns...${NC}"
        generate_png "all"
    else
        echo -e "${GREEN}Found $png_count PNG files${NC}"
        open graphics_*.png
    fi
}

# Function to clean up files
clean_files() {
    echo -e "${YELLOW}🧹 Cleaning up generated files...${NC}"
    
    files_to_clean="graphics_*.png *.vcd *.vvp temp/*"
    
    for pattern in $files_to_clean; do
        if ls $pattern 1> /dev/null 2>&1; then
            rm -f $pattern
            echo -e "${GREEN}🗑️ Removed: $pattern${NC}"
        fi
    done
    
    echo -e "${GREEN}✅ Cleanup completed${NC}"
}

# Function to run comprehensive test
run_test() {
    echo -e "${PURPLE}🧪 Running graphics system test...${NC}"
    
    # Generate test patterns
    echo -e "${BLUE}1. Generating test patterns...${NC}"
    python3 png_graphics_generator.py test_pattern
    
    # Build and run simulation if possible
    echo -e "${BLUE}2. Testing simulation build...${NC}"
    if [ -f "build_display_system.sh" ]; then
        ./build_display_system.sh
    else
        echo -e "${YELLOW}⚠️ No build script found, skipping simulation${NC}"
    fi
    
    # Test interactive viewer
    echo -e "${BLUE}3. Testing interactive viewer...${NC}"
    python3 mac_graphics_viewer.py static color_bars &
    VIEWER_PID=$!
    sleep 3
    kill $VIEWER_PID 2>/dev/null || true
    
    echo -e "${GREEN}✅ Graphics system test completed${NC}"
}

# Main command processing
COMMAND=${1:-"help"}

# Always check dependencies first (except for help and clean)
if [ "$COMMAND" != "help" ] && [ "$COMMAND" != "clean" ]; then
    check_dependencies
fi

case $COMMAND in
    "png")
        PATTERN=${2:-"all"}
        generate_png "$PATTERN"
        ;;
    "view")
        PATTERN=${2:-"color_bars"}
        view_graphics "$PATTERN"
        ;;
    "demo")
        run_demo
        ;;
    "analyze")
        VCD_FILE=${2:-"testbench/system_with_display.vcd"}
        analyze_vcd "$VCD_FILE"
        ;;
    "gallery")
        open_gallery
        ;;
    "clean")
        clean_files
        ;;
    "test")
        run_test
        ;;
    "help")
        show_help
        ;;
    *)
        echo -e "${RED}⚠️ Unknown command: $COMMAND${NC}"
        echo "Use '$0 help' for usage information"
        exit 1
        ;;
esac

echo -e "${GREEN}✅ Mac Graphics Suite completed${NC}"
