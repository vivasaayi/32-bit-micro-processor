# AruviOS Roadmap (RV32 Focus)

## Current Status ✅
- **RV32 Kernel**: Fully functional on QEMU virt machine
- **Interactive Shell**: UART-based command interface working
- **QEMU Testing**: Cross-platform development environment ready
- **AruviX Hardware**: Ready for FPGA deployment

## Next Steps

### Phase 1 (Immediate - AruviX Hardware Port)
- [ ] Switch to `aruvix-hw` feature for custom UART @ 0xF0000000
- [ ] Test on AruviX RISC processor FPGA
- [ ] Validate hardware-specific peripherals

### Phase 2 (Vertical Stack Integration)
- [ ] Integrate JVM interpreter with OS
- [ ] Add assembler execution environment
- [ ] Connect compiler output to OS
- [ ] Implement file I/O for source code

### Phase 3 (Enhanced OS Features)
- [ ] Add timer interrupts and system clock
- [ ] Implement basic memory management
- [ ] Add system calls for I/O operations
- [ ] Create process model for running compiled programs

### Phase 4 (Advanced Features)
- [ ] Add ELF loader for RV32 binaries
- [ ] Implement filesystem on flash storage
- [ ] Add networking support
- [ ] Create development tools (debugger, profiler)
- Add tiny libc shim for utilities.
- Add package script to bundle utilities into disk image.
