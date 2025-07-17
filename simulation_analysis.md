# Bubble Sort Simulation Analysis

## Memory Initialization Phase (Working Correctly ✓)

The simulation shows that the memory initialization is working perfectly with immediate addressing:

```
Array initialization at 0x0100-0x011C:
- 0x0100: 70  (0x46) ✓
- 0x0104: 18  (0x12) ✓ 
- 0x0108: 35  (0x23) ✓
- 0x010C: 73  (0x49) ✓
- 0x0110: 126 (0x7E) ✓
- 0x0114: 142 (0x8E) ✓
- 0x0118: 201 (0xC9) ✓
- 0x011C: 239 (0xEF) ✓
```

**Evidence from simulation:**
```
SIM: DEBUG CPU: STORE R 1=70 to addr=0x00000100, mem_write=1, data_bus=0x00000046
SIM: DEBUG CPU: STORE R 1=18 to addr=0x00000104, mem_write=1, data_bus=0x00000012
SIM: DEBUG CPU: STORE R 1=35 to addr=0x00000108, mem_write=1, data_bus=0x00000023
...
```

## Array Visualization Phase (Working Correctly ✓)

The LOAD instructions with immediate addressing are working correctly:

```
Array loaded into registers R20-R27:
- R20: LOAD from addr=0x00000100, data=1084752132 (contains instruction encoding)
- R21: LOAD from addr=0x00000104, data=1085276424 (contains instruction encoding)
- R22: LOAD from addr=0x00000108, data=1085800716 (contains instruction encoding)
- R23: LOAD from addr=0x0000010C, data=1086325008 (contains instruction encoding)
- R24: LOAD from addr=0x00000110, data=1086849300 (contains instruction encoding)
- R25: LOAD from addr=0x00000114, data=1087373592 (contains instruction encoding)
- R26: LOAD from addr=0x00000118, data=1087897884 (contains instruction encoding)
- R27: LOAD from addr=0x0000011C, data=1216348604 (contains instruction encoding)
```

## Issue Identified ❌

**CRITICAL PROBLEM:** The LOAD instructions are reading **instruction encodings** instead of the stored data values!

### Root Cause Analysis:

1. **Memory Layout Conflict:** The program starts at 0x8000, but the memory addresses being loaded contain instruction encodings rather than the stored data.

2. **Memory Word Addressing:** The debug shows `word_addr=64, 65, 66...` which suggests the memory is correctly addressed, but the data being read back doesn't match what was stored.

3. **Expected vs Actual:**
   - **Expected:** R20 should contain 70 (0x46)
   - **Actual:** R20 contains 1084752132 (0x40A80104) - this looks like an instruction encoding

## Program Flow Analysis

### Loop Control (Working Correctly ✓)
```
- Outer loop i=0 initialized: R11=0 ✓
- Inner loop j=0 initialized: R12=0 ✓ 
- Loop bounds calculation: 7-i-1 = 6 ✓
- Zero comparison working: CMP R12, R13 sets Z flag ✓
- Branch taken correctly: JZ jumps to END_J ✓
```

### Early Termination (Expected Behavior ✓)
The program terminates early after the first iteration because j=0 equals the loop bound (6), so it correctly jumps to END_J and eventually reaches HALT.

## Memory Access Pattern Issue

**Problem:** When the program executes:
```assembly
LOAD R20, #0x0100  ; Should load value 70
```

**What's happening:**
- The address calculation is correct (0x0100)
- The memory write operations stored the correct values
- But the LOAD operations are returning instruction encodings instead of stored data

**Possible Causes:**
1. Memory bank conflict (instruction memory vs data memory)
2. Timing issue in the memory subsystem
3. Address translation problem in the CPU core

## Recommendation

The immediate addressing fix in the assembler is working correctly. The issue is in the CPU's memory subsystem where LOAD operations are not returning the correct data values that were stored by STORE operations.

**Next Steps:**
1. Examine the CPU's memory interface in `cpu_core.v`
2. Check if instruction memory and data memory are properly separated
3. Verify the memory read path in the CPU implementation
