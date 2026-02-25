# DOS-like Readiness Review (Current State)

## Short answer
Not yet fully ready for external program loading/execution. The current shell executes **built-in Rust functions**, not packaged user binaries.

## Requirement-by-requirement status

1. **Build OS and open in VirtualBox**
   - Status: **Partially ready**
   - We can build a raw boot image and convert it to VDI using `make vdi` (requires `VBoxManage`).

2. **DOS-like operating system**
   - Status: **Early prototype**
   - Command prompt and basic command dispatch exist.

3. **CLI when OS starts**
   - Status: **Ready**
   - Boot shows prompt and accepts keyboard/serial input.

4. **Ship simple programs**
   - Status: **Partially ready**
   - Host-side samples are built and bundled (`make bundle-programs`), but the kernel does not load this bundle yet.

5. **Type command and execute program**
   - Status: **Partially ready**
   - Works for built-ins (`run echo`, `run sum`, `run about`) only.

6. **Program stdin/stdout**
   - Status: **Not ready for external user programs**
   - stdin/stdout works in shell path and built-ins via keyboard/serial + VGA/serial mirror, but no process/ABI boundary exists yet.

## What is missing for true DOS-like external apps

- Utility binary format for your CPU (RISC ISA target).
- Loader (read program bytes from storage and map into memory).
- Process model (register context, stack, exit path).
- Syscall ABI (at minimum: read/write/exit).
- Filesystem/disk layout for shipping multiple utility binaries.

## Packaging focus (next practical step)

1. Choose executable format (flat binary first, then ELF).
2. Add a read-only bundled "program volume" with manifest.
3. Add `run <name>` path to resolve name -> load bytes -> jump to entry.
4. Add syscall gateway for stdin/stdout.
