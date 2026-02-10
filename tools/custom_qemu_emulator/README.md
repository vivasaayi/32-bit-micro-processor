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
cd tools/custom_qemu_emulator
cargo run -- ../../test_programs/assembly/0_9_0_simple_store_test.asm --dump-addr 0x100
```

Optional flags:

```bash
cargo run -- <program.asm> --trace --max-steps 200000 --dump-addr 0x2000
```

## Tests

```bash
cd tools/custom_qemu_emulator
cargo test
```
