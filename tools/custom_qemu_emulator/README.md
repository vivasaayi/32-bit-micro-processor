# Custom QEMU-like Emulator (Educational)

This folder contains a lightweight **software emulator** for the repository's custom 32-bit assembly dialect. It is intended for learning and differential checking against existing RISC emulators/cores.

## Why this exists

- Understand fetch/decode/execute behavior under the hood.
- Verify assembly programs before RTL simulation.
- Compare outcomes against QEMU/other RISC cores to find semantic mismatches.

## Scope

Implemented instructions:

- Data: `LOADI`, `LOAD`, `STORE`
- ALU: `ADD`, `ADDI`, `SUB`, `SUBI`, `AND`, `OR`, `XOR`, `SHL`, `SHR`, `CMP`
- Control flow: `JMP`, `JZ`, `JNZ`, `JC`, `JNC`, `JLT`, `JGE`, `JLE`
- System: `HALT`

Notes:
- `R0` is hardwired to zero.
- Memory is 1MB and word-addressable via aligned 32-bit reads/writes.
- Labels are supported.

## Run

```bash
cd tools/custom_qemu_emulator
python3 emulator.py ../../test_programs/assembly/0_9_0_simple_store_test.asm
```

Optional flags:

```bash
python3 emulator.py <program.asm> --trace --max-steps 200000 --dump-addr 0x2000
```

## Tests

```bash
cd tools/custom_qemu_emulator
python3 -m unittest -v test_emulator.py
```

## Example output

```text
halted=True steps=8 pc=8 flags(C=1 Z=0 N=0 V=0) R1=0x0000002A
mem[0x00002000] = 0x0000002A (42)
```
