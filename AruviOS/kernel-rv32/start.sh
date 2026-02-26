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
echo "=========================================="
echo ""

# Launch QEMU with pipe serial
PIPE="/tmp/aruvios_serial_$$"
mkfifo "$PIPE"

echo "Starting AruviOS RV32..."
echo "Serial pipe: $PIPE"
echo ""
echo "To send commands from another terminal:"
echo "  echo 'help' > $PIPE"
echo "  ./send_command.sh $PIPE help"
echo "  ./send_command.sh $PIPE 'echo hello world'"
echo ""
echo "Available commands: help, echo, sum, mem, memw, clear"
echo "Exit QEMU: Ctrl-C"
echo ""

qemu-system-riscv32 \
    -machine virt \
    -cpu rv32 \
    -m 128M \
    -bios none \
    -nographic \
    -serial pipe:"$PIPE" \
    -kernel "$KERNEL_ELF" &

QEMU_PID=$!

# Cleanup on exit
trap "kill $QEMU_PID 2>/dev/null; rm -f $PIPE" EXIT

# Show output from pipe
cat "$PIPE" &
CAT_PID=$!

# Wait for QEMU
wait $QEMU_PID