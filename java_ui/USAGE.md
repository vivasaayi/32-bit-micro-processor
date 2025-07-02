# Custom CPU IDE

A Java Swing-based Integrated Development Environment for developing, compiling, and simulating programs for your custom CPU architecture.

## Features

- **Multi-language support**: C, Java, Assembly, Hex, Verilog
- **Integrated compilation**: Built-in support for your custom C compiler and assembler
- **Simulation interface**: Verilog simulation with live output monitoring
- **File tree navigation**: Easy browsing of test programs
- **Tabbed interface**: Organized workspace with dedicated tabs for each language/tool
- **Real-time monitoring**: File watchers for automatic reloading of generated files

## Tabs Overview

### 1. C Tab
- Edit C source code
- Compile using your custom C-to-Assembly compiler
- View compilation logs

### 2. Java Tab
- Edit Java source code
- Compile and view bytecode
- Bytecode explanation (coming soon)

### 3. Assembly Tab
- Edit assembly source code
- Assemble using your custom assembler
- View assembler logs and instruction explanations

### 4. Hex Tab
- View raw hex files
- Disassemble hex to instruction table
- Opcode explanations

### 5. Simulation Tab
- Load Verilog files
- Run simulations
- Monitor CPU registers and memory
- Live UART output

### 6. Simulation Log Tab
- Complete simulation output logs
- Auto-scroll and filtering options

### 7. Terminal Tab
- Framebuffer viewer for graphics output
- Text console for UART output
- Keyboard input simulation

### 8. VCD Tab
- VCD file viewer
- Signal timeline analysis
- Memory state inspection

## Getting Started

### Prerequisites
- Java 8 or higher
- Your custom C compiler at `/Users/rajanpanneerselvam/work/hdl/compiler/ccompiler`
- Your custom assembler
- Icarus Verilog (for simulation)

### Building and Running

```bash
# Build the project
make compile

# Run the IDE
make run

# Or use the build script
./build.sh

# Clean build artifacts
make clean
```

### Usage

1. **Open a file**: Use File > Open to select files from the test_programs directory
2. **Edit code**: The appropriate tab will be activated based on file type
3. **Compile**: Use the compile buttons in each tab
4. **Simulate**: Switch to Simulation tab and click "Simulate"
5. **Monitor output**: Check Terminal and Simulation Log tabs for results

## Keyboard Shortcuts

- `Ctrl+O`: Open file
- `Ctrl+S`: Save current file
- `Ctrl+R`: Run simulation
- `Ctrl+Tab`: Next tab
- `Ctrl+1-8`: Switch to specific tab

## File Organization

```
java_ui/
├── src/
│   ├── main/
│   │   └── CpuIDE.java          # Main application class
│   ├── tabs/
│   │   ├── BaseTab.java         # Base class for all tabs
│   │   ├── CTab.java            # C programming tab
│   │   ├── JavaTab.java         # Java programming tab
│   │   ├── AssemblyTab.java     # Assembly programming tab
│   │   ├── HexTab.java          # Hex viewer/editor tab
│   │   ├── SimulationTab.java   # Simulation control tab
│   │   ├── SimulationLogTab.java # Simulation output tab
│   │   ├── TerminalTab.java     # Terminal/framebuffer tab
│   │   └── VcdTab.java          # VCD analysis tab
│   └── util/
│       ├── AppState.java        # Application state management
│       └── FileWatcher.java     # File monitoring utility
├── build/                       # Compiled classes
├── Makefile                     # Build configuration
├── build.sh                     # Build script
└── README.md                    # This file
```

## Configuration

The IDE automatically looks for files in:
- Test programs: `/Users/rajanpanneerselvam/work/hdl/test_programs`
- C compiler: `/Users/rajanpanneerselvam/work/hdl/compiler/ccompiler`

Modify the path constants in `CpuIDE.java` if your setup differs.

## License

This project is part of the custom CPU development toolkit.
