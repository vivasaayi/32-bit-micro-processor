# Assembler vs RISC-V standard (RV32I/RV32M) gap analysis

This repository's assembler (`tools/assembler.c`) is **partially RV32I/RV32M compatible**.

## What is supported

- Most core RV32I integer instructions are present (`LUI/AUIPC/JAL/JALR`, branches, loads/stores, `ADDI/SLTI/...`, `ADD/SUB/...`).
- RV32M integer multiply/divide instructions (`MUL*`, `DIV*`, `REM*`) are present.
- Some privileged/system instructions are present (`ECALL`, `EBREAK`, `MRET`) and base CSR register forms (`CSRRW/CSRRS/CSRRC`).
- Register naming supports `xN` and ABI names (`ra/sp/gp/tp/t*/s*/a*`) plus legacy `rN` aliases.

## Deviations from RISC-V standard/toolchain behavior

1. **SRL/SRA encoding is swapped in the assembler table**
   - `SRL` is encoded with `funct7=0x20`, and `SRA` with `funct7=0x00`.
   - Standard encoding should be the opposite (`SRL=0x00`, `SRA=0x20`).
   - This is a true ISA encoding mismatch relative to RV32I and can break compatibility with standard binaries/disassemblers.

2. **System instruction coverage is incomplete vs standard assemblers**
   - Only `CSRRW/CSRRS/CSRRC` are implemented.
   - Missing common standard CSR immediate forms (`CSRRWI/CSRRSI/CSRRCI`) and aliases (`CSRR`, `CSRW`, `CSRS`, `CSRC`).
   - `FENCE` and `FENCE.I` are not defined.

3. **Assembler syntax is custom (not GNU `as` compatible)**
   - Accepts legacy bracket memory syntax (`[r1+4]`) in addition to `offset(rs1)`.
   - Comment stripping removes `#...` at line level, which diverges from many toolchains and can conflict with immediate conventions.
   - Directive set is minimal (`.org`, `.word`, `.string`, `.byte`, `.half`, `.align`), with no `.text/.data/.section/.globl/.ascii/.asciz` handling.

4. **Output format is raw words, not ELF/object format**
   - Hex output is plain 32-bit words per line.
   - Binary output is raw little-endian words.
   - This is fine for your custom CPU flow, but deviates from standard RISC-V toolchain artifacts.

5. **Additional non-standard pseudos are intentionally supported**
   - Includes convenience/legacy pseudo-op families like `JMP/JZ/JNZ/BGT/BLE/LOADI/HALT`.
   - Useful for this project, but not part of standard RISC-V ISA assembly grammar.

## Quick empirical spot-check

Built local assembler and assembled:

```asm
SRL x1, x2, x3
SRA x4, x5, x6
MRET
```

Observed machine code:

- `SRL x1, x2, x3` -> `0x403150B3` (this is SRA encoding in standard RV32I)
- `SRA x4, x5, x6` -> `0x0062D233` (this is SRL encoding in standard RV32I)
- `MRET` -> `0x30200073` (matches standard)

## Bottom line

- **Yes**, the assembler targets RV32I+RV32M and supports a large subset.
- **No**, it is not fully RISC-V-standard assembler compatible yet.
- The **highest-impact deviation** is the swapped SRL/SRA encoding.
