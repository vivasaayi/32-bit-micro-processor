# Custom Emulator (Rust)

This folder now contains a **Rust implementation** of a lightweight educational emulator for the repo's custom 32-bit assembly dialect.

## Why Rust

- Better runtime safety and performance than scripting for longer runs.
- Easier evolution toward bigger features (MMIO, traps, differential harnesses).
- Keeps the emulator readable and testable.

## Implemented instruction scope

- Data: `LOADI`, `LOAD`, `STORE`
- ALU: `ADD`, `ADDI`, `SUB`, `SUBI`, `AND`, `OR`, `XOR`, `SHL`, `SHR`, `CMP`
- Control flow: `JMP`, `JZ`, `JNZ`, `JC`, `JNC`, `JLT`, `JGE`, `JLE`
- System: `HALT`

### Execution model

- 32 registers (`R0..R31`), with `R0` hardwired to zero.
- 1MB little-endian memory.
- 32-bit aligned word `LOAD/STORE`.
- Labels are supported.
- Dot directives such as `.org` are ignored by the parser for compatibility with existing samples.

## Build and run

```bash
cd AruviEmulator
cargo run -- ../test_programs/assembly/0_9_0_simple_store_test.asm --dump-addr 0x100
```

Optional flags:

```bash
cargo run -- <program.asm> --trace --max-steps 200000 --dump-addr 0x2000
```

## Tests

```bash
cd AruviEmulator
cargo test
```


## Instruction statements (quick reference)

Use these exact assembly statement patterns for each supported instruction:

```asm
; Data movement
LOADI R1, #123
LOAD  R2, #0x300
STORE R2, #0x304

; Arithmetic
ADD  R3, R1, R2
ADDI R3, R3, #1
SUB  R4, R3, R1
SUBI R4, R4, #2

; Logic
AND R5, R1, R2
OR  R6, R1, R2
XOR R7, R1, R2

; Shifts
SHL R8, R1, #3
SHR R9, R8, #1

; Compare + branches
CMP R1, R2
JMP LABEL
JZ  LABEL
JNZ LABEL
JC  LABEL
JNC LABEL
JLT LABEL
JGE LABEL
JLE LABEL

; Stop
HALT
```

## Local unit-test workflow (before and after reload)

You can run these any time, even after reloading the environment:

```bash
cd AruviEmulator
cargo test instruction_tests -- --nocapture
cargo test
```

The test suite is intentionally instruction-focused, so each instruction has at least one direct test and several branch/memory/error behavior checks.
