# Mac Graphics Suite for RISC Processor
## Complete Graphics Visualization Solution for macOS

This document describes the comprehensive graphics visualization suite specifically designed for macOS compatibility with the RISC processor display system.

## 🖼️ Overview

The Mac Graphics Suite provides multiple ways to visualize and test the RISC processor's display output on macOS:

1. **Static PNG Generation** - Create high-quality PNG images
2. **Interactive Matplotlib Viewer** - Real-time graphics visualization  
3. **Web-based Viewer** - Browser-based display (already implemented)
4. **VCD Analysis** - Extract graphics data from simulation files
5. **Gallery Mode** - View all generated images at once

## 📁 Files in the Mac Graphics Suite

### Core Scripts
- `mac_graphics_suite.sh` - Main control script with all features
- `mac_graphics_viewer.py` - Interactive matplotlib-based viewer
- `png_graphics_generator.py` - Static PNG image generator
- `mac_graphics.sh` - Simple graphics viewing script

### Existing Components
- `vga_display_simulator.py` - VGA simulation with PNG output
- `web_graphics_viewer.py` - Web-based HTML viewer
- `live_console_monitor.py` - Real-time console monitoring

## 🚀 Quick Start

### 1. Basic Usage
```bash
# Show help
./mac_graphics_suite.sh help

# Generate all PNG patterns
./mac_graphics_suite.sh png all

# View interactive graphics
./mac_graphics_suite.sh view checkerboard

# Open gallery of all images
./mac_graphics_suite.sh gallery
```

### 2. Interactive Viewing
```bash
# View static pattern with matplotlib
./mac_graphics_suite.sh view color_bars

# Run animated demo sequence
./mac_graphics_suite.sh demo

# Test pattern for display verification
./mac_graphics_suite.sh png test_pattern
```

### 3. Analysis and Testing
```bash
# Analyze VCD simulation file
./mac_graphics_suite.sh analyze testbench/system_with_display.vcd

# Run comprehensive system test
./mac_graphics_suite.sh test

# Clean up generated files
./mac_graphics_suite.sh clean
```

## 🎨 Available Graphics Patterns

### Pattern Types
1. **color_bars** - Vertical RGB color bars for display testing
2. **checkerboard** - Black and white checkerboard pattern
3. **gradient** - Smooth color gradient from left to right
4. **circles** - Colorful circular patterns
5. **test_pattern** - Comprehensive test with lines, markers, and center circle
6. **text_demo** - Text display demonstration with timestamps

### Examples
```bash
# Generate specific pattern
./mac_graphics_suite.sh png gradient

# View specific pattern interactively
./mac_graphics_suite.sh view circles

# Generate and view all patterns
./mac_graphics_suite.sh png all
./mac_graphics_suite.sh gallery
```

## 🔧 Technical Details

### Dependencies
The suite automatically checks and installs required dependencies:
- Python 3
- matplotlib (for graphics generation and viewing)
- Pillow (for image processing)

### macOS Compatibility
- Uses matplotlib with macOS-compatible backends
- Integrates with macOS `open` command for image viewing
- Handles Unicode emoji display issues gracefully
- Non-blocking background execution for interactive viewers

### File Outputs
- PNG images: `graphics_[pattern]_[timestamp].png`
- VCD analysis output to console
- Temporary files in `temp/` directory

## 📊 Integration with RISC Processor

### Hardware Integration
```verilog
// VGA display controller
io/display_controller.v       // 640x480 VGA output
io/char_rom.hex              // Character ROM data

// System integration
microprocessor_system_with_display.v
```

### Software Integration
```c
// CLI framework for display control
software/cli.h
software/cli.c

// Demo programs
software/*_demo.c
```

### Simulation Integration
```bash
# Build and test display system
./build_display_system.sh
./integrate_display_system.sh

# Analyze simulation results
./mac_graphics_suite.sh analyze testbench/system_with_display.vcd
```

## 🎯 Use Cases

### 1. Display Testing
```bash
# Generate test patterns for display verification
./mac_graphics_suite.sh png test_pattern
./mac_graphics_suite.sh png color_bars
```

### 2. Development Debugging
```bash
# Interactive viewing during development
./mac_graphics_suite.sh view checkerboard

# Real-time simulation monitoring
python3 live_console_monitor.py --graphics-demo
```

### 3. Demonstration and Documentation
```bash
# Create presentation materials
./mac_graphics_suite.sh png all
./mac_graphics_suite.sh gallery

# Interactive demos
./mac_graphics_suite.sh demo
```

### 4. Simulation Analysis
```bash
# Extract graphics data from VCD files
./mac_graphics_suite.sh analyze my_simulation.vcd

# Comprehensive system test
./mac_graphics_suite.sh test
```

## 🔍 Troubleshooting

### Common Issues

#### 1. Matplotlib Window Not Showing
```bash
# Try different backend
export MPLBACKEND=TkAgg
./mac_graphics_suite.sh view color_bars
```

#### 2. Missing Dependencies
```bash
# Manual installation
pip3 install matplotlib pillow numpy
```

#### 3. Permission Issues
```bash
# Make scripts executable
chmod +x mac_graphics_suite.sh
chmod +x mac_graphics.sh
```

#### 4. Unicode Display Issues
The scripts handle Unicode emoji display warnings gracefully - functionality is not affected.

### Alternative Methods

If interactive viewing doesn't work:
1. Use PNG generation: `./mac_graphics_suite.sh png all`
2. Use web viewer: `python3 web_graphics_viewer.py`
3. Use simple browser: Open generated HTML files

## 📈 Performance Notes

### Resource Usage
- PNG generation: Low CPU, creates ~50KB files
- Interactive viewing: Moderate CPU for real-time updates
- VCD analysis: Depends on file size, typically fast

### Optimization Tips
- Use PNG generation for batch processing
- Use interactive viewer for development
- Use web viewer for remote access

## 🔮 Future Enhancements

### Potential Additions
1. Real-time VCD streaming visualization
2. Custom pattern editor
3. Hardware signal overlay
4. Performance profiling integration
5. Multiple display format support

### Integration Opportunities
1. Direct hardware communication
2. FPGA synthesis integration
3. Automated testing framework
4. CI/CD pipeline integration

## 📚 Related Documentation

- `DISPLAY_SYSTEM_README.md` - Complete display system overview
- `docs/instruction_set.md` - Processor instruction reference
- VGA controller documentation in `io/display_controller.v`
- Software framework in `software/cli.h`

## ✅ Verification Checklist

- [x] PNG generation working
- [x] Interactive matplotlib viewer working
- [x] Gallery mode functional
- [x] VCD analysis operational
- [x] macOS integration complete
- [x] Dependency management automated
- [x] Error handling implemented
- [x] Documentation complete

The Mac Graphics Suite provides a complete, Mac-native solution for visualizing and testing the RISC processor's display capabilities.
