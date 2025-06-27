#!/bin/bash

# Build script for 8-bit Microprocessor Project
# This script builds and tests the entire system

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}8-Bit Microprocessor Build Script${NC}"
echo "=================================="

# Check if required tools are installed
check_tools() {
    echo -e "${YELLOW}Checking required tools...${NC}"
    
    if ! command -v iverilog &> /dev/null; then
        echo -e "${RED}Error: Icarus Verilog not found. Install with: brew install icarus-verilog${NC}"
        exit 1
    fi
    
    if ! command -v python3 &> /dev/null; then
        echo -e "${RED}Error: Python 3 not found.${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✓ All required tools found${NC}"
}

# Clean previous builds
clean() {
    echo -e "${YELLOW}Cleaning previous builds...${NC}"
    rm -f *.vvp *.vcd *.hex
    echo -e "${GREEN}✓ Clean complete${NC}"
}

# Assemble example programs
assemble() {
    echo -e "${YELLOW}Assembling example programs...${NC}"
    
    if [ -f "tools/assembler.py" ]; then
        python3 tools/assembler.py examples/hello_world.asm hello_world.hex
        python3 tools/assembler.py examples/mini_os.asm mini_os.hex
        echo -e "${GREEN}✓ Assembly complete${NC}"
    else
        echo -e "${YELLOW}Warning: Assembler not found, skipping assembly${NC}"
    fi
}

# Build HDL
build() {
    echo -e "${YELLOW}Building HDL design...${NC}"
    
    # Create the VVP file
    iverilog -o microprocessor_system.vvp \
        cpu/cpu_core.v \
        cpu/alu.v \
        cpu/register_file.v \
        cpu/control_unit.v \
        memory/memory_controller.v \
        memory/mmu.v \
        io/uart.v \
        io/timer.v \
        io/interrupt_controller.v \
        microprocessor_system.v \
        testbench/tb_microprocessor_system.v
    
    echo -e "${GREEN}✓ Build complete${NC}"
}

# Run simulation
simulate() {
    echo -e "${YELLOW}Running simulation...${NC}"
    
    if [ -f "microprocessor_system.vvp" ]; then
        vvp microprocessor_system.vvp
        echo -e "${GREEN}✓ Simulation complete${NC}"
    else
        echo -e "${RED}Error: No simulation file found. Build first.${NC}"
        exit 1
    fi
}

# View waveforms (if available)
waveforms() {
    echo -e "${YELLOW}Opening waveforms...${NC}"
    
    if [ -f "microprocessor_system.vcd" ]; then
        if command -v gtkwave &> /dev/null; then
            gtkwave microprocessor_system.vcd &
            echo -e "${GREEN}✓ GTKWave opened${NC}"
        else
            echo -e "${YELLOW}Warning: GTKWave not found. Install with: brew install gtkwave${NC}"
        fi
    else
        echo -e "${YELLOW}Warning: No waveform file found. Run simulation first.${NC}"
    fi
}

# Print usage
usage() {
    echo "Usage: $0 [command]"
    echo "Commands:"
    echo "  check     - Check required tools"
    echo "  clean     - Clean build files"
    echo "  assemble  - Assemble example programs"
    echo "  build     - Build HDL design"
    echo "  sim       - Run simulation"
    echo "  wave      - View waveforms"
    echo "  all       - Do everything (default)"
    echo "  help      - Show this help"
}

# Main script logic
case "${1:-all}" in
    check)
        check_tools
        ;;
    clean)
        clean
        ;;
    assemble)
        assemble
        ;;
    build)
        build
        ;;
    sim)
        simulate
        ;;
    wave)
        waveforms
        ;;
    all)
        check_tools
        clean
        assemble
        build
        simulate
        echo -e "${GREEN}"
        echo "========================================"
        echo "Build and simulation completed!"
        echo "========================================"
        echo -e "${NC}"
        echo "Next steps:"
        echo "1. Run './build.sh wave' to view waveforms"
        echo "2. Examine the generated .vcd file"
        echo "3. Check the simulation output above"
        echo "4. Modify the design and re-run"
        ;;
    help)
        usage
        ;;
    *)
        echo -e "${RED}Unknown command: $1${NC}"
        usage
        exit 1
        ;;
esac
