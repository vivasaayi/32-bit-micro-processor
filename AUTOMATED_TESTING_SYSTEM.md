# Automated Testing System for HDL Project

## Overview
This document describes the automated testing system that was implemented to process all ASM files in the `examples/` directory. The system automatically assembles, simulates, and reports on each ASM program with full organization of generated files.

## System Components

### 1. Core Test Runner: `test_all_asm.py`
- **Purpose**: Python script that orchestrates the entire testing workflow
- **Features**:
  - Automatically discovers all `.asm` files in `examples/` directory
  - Assembles each ASM file using `tools/corrected_assembler.py`
  - Generates custom testbenches for each program
  - Compiles and simulates using iverilog/vvp
  - Organizes all generated files in structured temp directories
  - Produces comprehensive summary reports

### 2. Shell Wrapper: `run_all_tests.sh`
- **Purpose**: Convenient shell script to run the test system
- **Usage**: `./run_all_tests.sh`
- **Features**:
  - Executable script for easy invocation
  - Provides user-friendly output formatting
  - Displays final instructions for accessing results

### 3. File Organization Structure
All generated files are organized under `temp/` directory:

```
temp/
├── hex/                # Assembled machine code files
│   ├── advanced_test.hex
│   ├── bubble_sort.hex
│   └── ...
├── testbenches/        # Generated Verilog testbenches
│   ├── tb_advanced_test.v
│   ├── tb_bubble_sort.v
│   └── ...
├── vvp/               # Compiled simulation executables
│   ├── tb_advanced_test.vvp
│   ├── tb_bubble_sort.vvp
│   └── ...
├── vcd/               # Waveform files for GTKWave
│   ├── tb_advanced_test.vcd
│   ├── tb_bubble_sort.vcd
│   └── ...
└── reports/           # Simulation logs and summary
    ├── advanced_test_sim.log
    ├── bubble_sort_sim.log
    ├── ...
    └── summary.txt    # Master summary report
```

## Workflow Process

### Phase 1: Discovery
- Scans `examples/` directory for all `.asm` files
- Validates file accessibility and readability

### Phase 2: Assembly
- For each ASM file:
  - Invokes `python3 tools/corrected_assembler.py <input.asm> <output.hex>`
  - Generates HEX machine code files in `temp/hex/`
  - Creates memory initialization files (`.mem`) for testbenches

### Phase 3: Testbench Generation
- Creates custom Verilog testbench for each program:
  - Uses `$readmemh()` to load program memory
  - Provides clock and reset stimulus
  - Includes monitoring and debug output
  - Runs simulation for sufficient cycles (2000+ clock cycles)
  - Generates VCD files for waveform analysis

### Phase 4: Compilation & Simulation
- Compiles each testbench with iverilog:
  - Includes all HDL modules (CPU, memory, I/O)
  - Uses proper include paths
  - Generates VVP executable files
- Executes simulation with vvp:
  - Captures all output to log files
  - Generates VCD waveform files
  - Records timing and execution data

### Phase 5: Reporting
- Creates individual simulation logs for each test
- Generates master summary report with:
  - Success/failure statistics
  - File location references  
  - Performance metrics
  - Complete test inventory

## Test Results (Latest Run)

### Summary Statistics
- **Total ASM Files**: 9
- **Successful Tests**: 9 (100%)
- **Failed Tests**: 0 (0%)
- **Total Duration**: 0.57 seconds
- **Assembly Success Rate**: 9/9 (100%)
- **Simulation Success Rate**: 9/9 (100%)

### Tested Programs
✓ `advanced_test.asm` - Advanced instruction testing  
✓ `bubble_sort.asm` - Bubble sort algorithm  
✓ `bubble_sort_real.asm` - Real-world bubble sort  
✓ `comprehensive_test.asm` - Comprehensive CPU testing  
✓ `hello_world.asm` - Basic output program  
✓ `mini_os.asm` - Mini operating system  
✓ `simple_sort.asm` - Simple sorting routine  
✓ `simple_test.asm` - Basic functionality test  
✓ `sort_demo.asm` - Sorting demonstration  

## Usage Instructions

### Running All Tests
```bash
./run_all_tests.sh
```

### Running Individual Tests
```bash
python3 test_all_asm.py
```

### Viewing Results
- **Summary Report**: `cat temp/reports/summary.txt`
- **Individual Logs**: `cat temp/reports/<program>_sim.log`
- **Waveform Analysis**: `gtkwave temp/vcd/tb_<program>.vcd`

### Cleaning Generated Files
```bash
rm -rf temp/
```

## Technical Features

### Assembler Integration
- Uses corrected assembler with proper input/output argument handling
- Validates assembly success before proceeding to simulation
- Generates both HEX and MEM formats for different use cases

### Testbench Generation
- Dynamic testbench creation tailored to each program
- Proper memory initialization using `$readmemh()`
- Configurable simulation duration
- Comprehensive debug output and monitoring
- VCD generation for waveform analysis

### Error Handling
- Robust error detection at each stage
- Graceful failure handling with detailed error reporting
- Continues processing other files even if one fails
- Clear distinction between assembly and simulation failures

### Performance Optimization
- Efficient file operations
- Parallel-safe directory structure
- Minimal redundant operations
- Fast execution (< 1 second for 9 programs)

## Maintenance and Extension

### Adding New Test Programs
1. Place new `.asm` files in `examples/` directory
2. Run `./run_all_tests.sh` - new files will be automatically discovered

### Modifying Simulation Parameters
- Edit `test_all_asm.py` to adjust simulation duration
- Modify testbench template for different monitoring needs
- Update file organization structure as needed

### Integration with CI/CD
The automated testing system is designed for easy integration with continuous integration:
```bash
#!/bin/bash
# CI test script
./run_all_tests.sh
if [ $? -eq 0 ]; then
    echo "All tests passed!"
    exit 0
else
    echo "Tests failed!"
    exit 1
fi
```

## Conclusion

The automated testing system provides:
- **Complete Coverage**: Tests all ASM programs automatically
- **Clean Organization**: All generated files properly structured
- **Detailed Reporting**: Comprehensive success/failure tracking
- **Easy Usage**: Single command execution
- **Maintainability**: Easy to extend and modify
- **Integration Ready**: Suitable for CI/CD pipelines

This system ensures that all ASM programs can be quickly validated against the HDL implementation with minimal manual effort, making it an essential tool for project development and validation.
