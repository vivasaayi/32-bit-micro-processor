# Display System for Custom RISC Processor

## Overview
This display system adds comprehensive visual output capabilities to the custom RISC processor, including both text-based CLI and graphics capabilities.

## Architecture

### Components
1. **Display Controller** (`io/display_controller.v`)
   - Supports text mode (80x25 characters)
   - Supports graphics mode (640x480 pixels)
   - Supports mixed mode (graphics + text overlay)
   - VGA output compatible
   - Memory-mapped interface

2. **Enhanced Microprocessor System** (`microprocessor_system_with_display.v`)
   - Integrates CPU with display controller
   - Memory-mapped I/O for display access
   - Address decoding for display vs memory

3. **Software Libraries** (`software/`)
   - CLI framework with command processing
   - Graphics functions for pixel manipulation
   - Text output functions
   - Color management

### Memory Map
```
0x00000000 - 0xFEFFFFFF: Main Memory
0xFF000000 - 0xFF000FFF: Display Control Registers
0xFF001000 - 0xFF001F9F: Text Buffer (80x25 characters)
0xFF002000 - 0xFF04B000: Graphics Framebuffer (640x480)
0xFF050000 - 0xFF0500FF: Color Palette (256 colors)
```

### Display Modes
- **Text Mode (0)**: 80x25 character display with 16 colors
- **Graphics Mode (1)**: 640x480 pixel framebuffer with 256 colors
- **Mixed Mode (2)**: Graphics background with text overlay

## Usage

### Building Programs
```bash
# Compile display demo
./build_cli_demo.sh

# Build complete system
./integrate_display_system.sh
```

### Programming Interface

#### Text Output
```c
// Set display mode
write_display_reg(DISPLAY_MODE, MODE_TEXT);

// Write character at position
put_text_char(x, y, 'A', COLOR_WHITE);

// Set cursor position
write_display_reg(CURSOR_X, x);
write_display_reg(CURSOR_Y, y);
```

#### Graphics Output
```c
// Set graphics mode
write_display_reg(DISPLAY_MODE, MODE_GRAPHICS);

// Set pixel
put_pixel(x, y, color);

// Clear screen
for (int i = 0; i < 640*480; i++) {
    framebuffer[i] = COLOR_BLUE;
}
```

### CLI Commands
When running the CLI system:
- `help` - Show available commands
- `clear` - Clear screen
- `color fg bg` - Set text colors
- `mode 0|1|2` - Set display mode
- `pixel x y color` - Set pixel in graphics mode
- `line x1 y1 x2 y2 color` - Draw line
- `rect x y w h color` - Draw rectangle

## Demo Programs

### Simple Display Demo
- Demonstrates text mode with colored text
- Shows graphics mode with patterns and shapes
- Demonstrates mixed mode with text overlay

### CLI Demo (Advanced)
- Full command-line interface
- Interactive graphics commands
- Color and mode switching
- Pattern drawing capabilities

## Hardware Requirements

### VGA Output
- 640x480 resolution at 60Hz
- 8-bit RGB color output (256 colors)
- Standard VGA timing signals

### Memory
- Text buffer: 4KB (2000 characters × 2 bytes)
- Graphics framebuffer: 300KB (640×480 pixels)
- Palette RAM: 1KB (256 colors × 4 bytes)
- Control registers: 32 bytes

### Clock
- 100MHz system clock recommended
- 25MHz pixel clock for VGA (derived from system clock)

## Files

### Hardware
- `io/display_controller.v` - Main display controller
- `io/char_rom.hex` - Character font data
- `microprocessor_system_with_display.v` - Enhanced system

### Software
- `software/cli.h` - CLI library header
- `software/cli.c` - CLI implementation
- `software/simple_display_demo.c` - Basic demo
- `software/cli_demo_combined.c` - Advanced demo

### Build Scripts
- `build_cli_demo.sh` - Build CLI demonstration
- `integrate_display_system.sh` - Build complete system
- `tools/generate_char_rom.py` - Generate font data

### Test Benches
- `testbench/tb_system_with_display.v` - Complete system test
- `testbench/tb_cli_demo.v` - CLI-specific test

## Status
✅ **FULLY OPERATIONAL**

The display system is complete and functional:
- Hardware modules implemented and tested
- Software libraries created
- Demo programs working
- Integration with processor successful
- VGA output compatible
- Memory-mapped interface operational

## Next Steps
1. Add keyboard input support
2. Implement interrupt-driven display updates
3. Add hardware acceleration for graphics operations
4. Create window management system
5. Port existing applications to use display system
