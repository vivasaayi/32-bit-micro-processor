# AruviOS Readiness Review (RV32 Status)

## Current Status ✅

**RV32 Interactive OS**: Fully functional with UART-based shell on QEMU virt machine.

### What's Working
- ✅ **Bootable RV32 Kernel**: Rust no_std kernel for RV32IM ISA
- ✅ **UART Serial I/O**: Bidirectional communication via NS16550A
- ✅ **Interactive Shell**: Command processing with built-in utilities
- ✅ **QEMU virt Testing**: Cross-platform development environment
- ✅ **AruviX Ready**: Prepared for custom RISC processor deployment

### Available Commands
- `help` - Show available commands
- `echo <text>` - Print text to console
- `sum <numbers>` - Add numbers and display result
- `mem <address>` - Read memory/MMIO register
- `memw <address> <value>` - Write to memory
- `clear` - Clear screen

## Usage

```bash
# Build and run
cd kernel-rv32
./build_rv32.sh build
./start.sh

# Send commands from another terminal
./send_command.sh /tmp/aruvios_serial_XXXXX help
./send_command.sh /tmp/aruvios_serial_XXXXX "sum 10 20 30"
```

## Next Milestones

### AruviX Hardware Port
- Switch to `aruvix-hw` feature
- Test on FPGA with custom UART @ 0xF0000000
- Validate processor-specific peripherals

### Vertical Stack Integration
- JVM bytecode execution
- Assembler program running
- Compiler output integration
- Source code file I/O

### Advanced OS Features
- Memory management
- System calls
- Process model
- Filesystem support
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
