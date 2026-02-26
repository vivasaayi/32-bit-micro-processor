#!/usr/bin/env bash
#
# AruviOS RV32 — Quick Start Script
#
# Launches AruviOS RV32 kernel on QEMU riscv32 virt machine.
# The kernel must be built first (run ./build_rv32.sh build)
#
# Usage: ./start.sh
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

KERNEL_ELF="target/riscv32-aruvios/release/aruvios-rv32"

# Check if kernel exists
if [[ ! -f "$KERNEL_ELF" ]]; then
    echo "ERROR: Kernel not found at ${KERNEL_ELF}"
    echo "       Build it first: ./build_rv32.sh build"
    exit 1
fi

# Check for QEMU
if ! command -v qemu-system-riscv32 &>/dev/null; then
    echo "ERROR: qemu-system-riscv32 not found."
    echo "       Install with: brew install qemu"
    exit 1
fi

echo "=========================================="
echo "  AruviX HobbyOS (RV32) — Live Session"
echo "=========================================="
echo ""
echo "Kernel: ${KERNEL_ELF}"
echo "Platform: QEMU virt (riscv32)"
echo "UART: NS16550A @ 0x10000000"
echo ""
echo "Commands:"
echo "  help     - show all commands"
echo "  echo     - print text"
echo "  sum      - add numbers"
echo "  mem      - read memory/MMIO"
echo "  memw     - write memory"
echo "  clear    - clear screen"
echo ""
echo "Exit QEMU: Ctrl-A then X"
echo ""
echo "=========================================="
echo ""

# Launch QEMU interactively
exec qemu-system-riscv32 \
    -machine virt \
    -cpu rv32 \
    -m 128M \
    -bios none \
    -nographic \
    -kernel "$KERNEL_ELF"