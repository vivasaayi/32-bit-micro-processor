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
PIPE="/tmp/aruvios_serial_$$"

# Create named pipe
mkfifo "$PIPE"

# Launch QEMU with pipe serial
qemu-system-riscv32 \
    -machine virt \
    -cpu rv32 \
    -m 128M \
    -bios none \
    -nographic \
    -serial pipe:"$PIPE" \
    -kernel "$KERNEL_ELF" &

QEMU_PID=$!

# Function to cleanup on exit
cleanup() {
    kill $QEMU_PID 2>/dev/null
    rm -f "$PIPE"
    exit
}

trap cleanup INT TERM EXIT

# Display output from pipe
cat "$PIPE" &
CAT_PID=$!

# Wait for QEMU to start
sleep 2

echo "AruviOS RV32 interactive session started."
echo "Type commands at the '$ ' prompt."
echo "Available commands: help, echo, sum, mem, memw, clear"
echo "Exit with Ctrl-C"
echo ""

# Interactive input loop
while true; do
    read -r input
    echo "$input" > "$PIPE"
done