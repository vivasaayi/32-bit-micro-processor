# Investigation and Resolution: Immediate Encoding/Decoding and Program Loading Issues in Custom CPU/Assembler/Simulator Toolchain

## Overview
This document details the investigation, root cause analysis, and resolution of several critical issues encountered in the assembler, CPU, and analysis scripts for a custom CPU/assembler/simulator toolchain. The main focus was on the correct encoding and decoding of immediate values for JMP/branch instructions, proper handling of negative offsets, and ensuring the program is loaded at the correct address in memory. The investigation also uncovered and resolved issues with forward label references and instruction encoding.

---

## 1. Immediate Encoding/Decoding for JMP/Branch Instructions

### Problem
- JMP/branch instructions were using only 9 bits for the immediate field, instead of the required 12 bits.
- This caused incorrect encoding of negative offsets (e.g., -5), leading to failed or incorrect branching.
- The assembler, CPU, and analysis scripts were not in agreement on how to encode/decode these immediates.

### Investigation
- The assembler was masking immediates with `0x1FF` (9 bits) instead of `0xFFF` (12 bits) for JMP/branch instructions.
- The CPU instruction decoder was also extracting only 9 bits for the immediate field.
- The Python analysis script was decoding only 9 bits for two's complement immediates.

### Solution
- Updated the assembler to encode 12-bit immediates for JMP/branch instructions (mask with `0xFFF`).
- Updated the CPU to extract and sign-extend 12-bit immediate fields.
- Updated the analysis script to decode 12-bit two's complement immediates.
- Verified that assembler, CPU, and analysis script now agree on encoding/decoding and target address calculation.

---

## 2. Program Loading Address

### Problem
- The program was being loaded at memory index 0, but the CPU starts execution at PC=0x8000 (memory index 8192).
- This caused the CPU to execute unintended instructions or invalid memory.

### Investigation
- The testbench was loading the program at the wrong offset.

### Solution
- Updated the testbench to load the program at the correct memory offset (8192 for PC=0x8000).
- Confirmed that the CPU now executes the intended instructions.

---

## 3. Forward Label References in Branches

### Problem
- The assembler was not resolving forward label references in branches (e.g., `JZ end_mul`), resulting in incorrect offsets (always 0).

### Investigation
- The assembler performed only a single pass, so forward references could not be resolved.

### Solution
- Implemented a two-pass assembly system with forward reference tracking and resolution.
- In the first pass, instructions with unresolved labels are marked and stored with metadata.
- In the second pass, all label addresses are known, and forward references are resolved to correct offsets or absolute addresses as needed.

---

## 4. CMP Instruction Encoding

### Problem
- The assembler was encoding `CMP R2, R0` as `rd=R2, rs1=R0`, which is incorrect.

### Investigation
- The correct encoding for CMP is to use `rs1` and `rs2` fields, not `rd`.

### Solution
- Fixed the assembler to encode CMP instructions as `rs1=R2, rs2=R0` (with `rd=0`).

---

## 5. Verification and Results

- Rebuilt the assembler, reassembled the test program, and verified the correct hex output.
- Ran the simulation and confirmed correct loop/branch behavior and program result (e.g., 7×6=42).
- All changes were verified by rebuilding, reassembling, and running the simulation.

---

## 6. Summary of Code Changes

- **Assembler (`assembler.c`):**
  - Changed immediate field masking from 9 bits to 12 bits for JMP/branch instructions.
  - Implemented two-pass assembly with forward reference tracking and resolution.
  - Added `is_label_name` function to distinguish labels from immediates.
  - Fixed CMP instruction encoding to use `rs1/rs2` fields, not `rd/rs1`.
  - Updated instruction storage to track forward reference metadata.
- **CPU:**
  - Updated instruction decoder to extract and sign-extend 12-bit immediates for JMP/branch.
- **Testbench:**
  - Ensured program is loaded at correct memory offset (8192 for PC=0x8000).
- **Analysis Script:**
  - Fixed decoding of 12-bit two's complement immediates.

---

## 7. Lessons Learned

- Always ensure that all components (assembler, CPU, analysis tools) agree on instruction encoding formats.
- Two-pass assembly is essential for correct label resolution, especially for forward references.
- Proper sign extension and field width handling are critical for correct program execution, especially for negative offsets in branches.
- Loading programs at the correct memory address is essential for correct CPU operation.

---

## 8. Status

- All issues have been resolved.
- The assembler, CPU, and analysis scripts are now consistent and correct.
- The test program executes as intended, with correct branching and results.

---

*Prepared July 16, 2025*
