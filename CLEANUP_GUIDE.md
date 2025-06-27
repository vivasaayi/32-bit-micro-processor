# HDL Project Cleanup Guide

## Files Analysis and Cleanup Recommendations

### 🗑️ **SAFE TO DELETE - Temporary/Generated Files**

#### Compiled Simulation Files (.vvp)
These are compiled Verilog simulation executables that can be regenerated:
```bash
# Individual component tests
alu_test.vvp
cpu_test.vvp
ctrl_test.vvp
int_test.vvp
mem_ctrl_test.vvp
mmu_test.vvp
reg_test.vvp
timer_test.vvp
uart_test.vvp
basic_test.vvp
test.vvp
```

#### Simulation Output Files (.vcd)
These are waveform data files from simulations:
```bash
bubble_sort.vcd
sort_demo.vcd
sort_simple.vcd
```

#### Compiled Executables (no extension)
These are compiled testbench executables:
```bash
alu_demo
array_sort_final
bubble_sort
comprehensive_final_sim
corrected_simple_test
debug_instructions
sort_demo
sort_simple
```

#### Assembled Program Files (.hex) - MOSTLY SAFE TO DELETE
These are assembler outputs that can be regenerated from source:
```bash
advanced_test.hex              # from examples/advanced_test.asm
bubble_sort_real.hex           # from examples/bubble_sort_real.asm
comprehensive_test.hex         # from examples/comprehensive_test.asm
comprehensive_test_corrected.hex # from examples/comprehensive_test.asm (corrected assembler)
comprehensive_test_full.hex    # from examples/comprehensive_test.asm
demo_comprehensive.hex         # from examples/comprehensive_test.asm
simple_sort.hex               # from examples/simple_sort.asm
simple_test.hex               # from examples/simple_test.asm
sort_demo.hex                 # from examples/sort_demo.asm
```

### ⚠️ **CONSIDER KEEPING - Working/Reference Files**

#### Key Documentation
```bash
FINAL_REPORT.md          # Project completion report
SORTING_REPORT.md        # Array sorting implementation report
PROJECT_SUMMARY.md       # Overall project summary
README.md               # Main project documentation
```

#### Essential Scripts
```bash
build.sh                # Build automation script
demo_system.sh          # System demonstration script
Makefile                # Build configuration
```

#### Debug/Analysis Files
```bash
debug_instructions.v     # Instruction debugging utility
```

#### Test Files That Might Be References
```bash
tb_full_system_demo.v    # Unused testbench (failed compilation)
tb_corrected_program.v   # Unused testbench
tb_sort_test.v          # Unused sorting testbench
```

### ✅ **KEEP - Essential Source Files**

#### Core System Files
```bash
microprocessor_system.v  # Main system integration
cpu/                     # CPU implementation directory
memory/                  # Memory subsystem directory
io/                      # I/O peripherals directory
testbench/              # Core testbenches directory
```

#### Working Source Code
```bash
examples/               # All assembly source programs
tools/                  # Assembler tools
docs/                   # Project documentation
```

#### Working Testbenches
```bash
tb_alu.v
tb_basic.v
tb_corrected_simple.v    # Working corrected program test
tb_comprehensive_final.v # Working comprehensive test
tb_array_sort_final.v    # Working array sort demonstration
tb_bubble_sort.v
tb_sort_demo.v
tb_sort_simple.v
```

## 🧹 **Cleanup Commands**

### Safe Cleanup (Remove generated/temporary files):
```bash
# Remove compiled simulation files
rm -f *.vvp

# Remove simulation waveform outputs
rm -f *.vcd

# Remove compiled executables
rm -f alu_demo array_sort_final bubble_sort comprehensive_final_sim
rm -f corrected_simple_test debug_instructions sort_demo sort_simple

# Remove assembled hex files (can be regenerated)
rm -f *.hex
```

### Conservative Cleanup (Keep some references):
```bash
# Remove only the obvious temporary files
rm -f *.vvp *.vcd
rm -f alu_demo array_sort_final bubble_sort sort_demo sort_simple

# Keep debug_instructions and comprehensive_final_sim as they might be useful
# Keep some key hex files like comprehensive_test_corrected.hex
```

### Aggressive Cleanup (Remove almost everything generated):
```bash
# Remove all generated/compiled files
rm -f *.vvp *.vcd *.hex
rm -f alu_demo array_sort_final bubble_sort comprehensive_final_sim
rm -f corrected_simple_test debug_instructions sort_demo sort_simple

# Remove unused testbenches
rm -f tb_full_system_demo.v tb_corrected_program.v tb_sort_test.v
```

## 📊 **Space Savings**

Estimated disk space that can be reclaimed:
- **.vvp files**: ~400KB (11 files)
- **.vcd files**: ~60KB (3 files)  
- **Compiled executables**: ~200KB (9 files)
- **.hex files**: ~230KB (9 files, including one large 115KB file)
- **Total potential savings**: ~890KB

## 🔄 **Regeneration Commands**

After cleanup, you can regenerate files as needed:

```bash
# Recompile individual tests
iverilog -o cpu_test.vvp testbench/tb_cpu_core.v cpu/*.v

# Reassemble programs
python3 tools/corrected_assembler.py examples/comprehensive_test.asm comprehensive_test_corrected.hex

# Rebuild working tests
iverilog -g2012 -o corrected_simple_test tb_corrected_simple.v
```

## 🎯 **Recommended Action**

**Conservative approach** - Run this command:
```bash
cd /Users/rajanpanneerselvam/work/hdl
rm -f *.vvp *.vcd
rm -f alu_demo array_sort_final bubble_sort sort_demo sort_simple
```

This removes ~660KB of clearly temporary files while keeping all source code, documentation, and key reference files intact.
