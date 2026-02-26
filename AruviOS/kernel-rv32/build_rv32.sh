#!/usr/bin/env bash
#
# Build and run AruviOS RV32 kernel on QEMU
#
# Usage:
#   ./build_rv32.sh              # Build + run on QEMU virt (default)
#   ./build_rv32.sh build        # Build only
#   ./build_rv32.sh run          # Run only (must build first)
#   ./build_rv32.sh aruvix       # Build for AruviX hardware target
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

TARGET="riscv32-aruvios"
KERNEL_ELF="target/${TARGET}/release/aruvios-rv32"
FEATURES="qemu-virt"
MODE="all"

# Parse arguments
case "${1:-}" in
    build)  MODE="build" ;;
    run)    MODE="run" ;;
    aruvix)
        FEATURES="aruvix-hw"
        MODE="build"
        echo "=== Building for AruviX hardware ==="
        ;;
    *)      MODE="all" ;;
esac

# ── Build ─────────────────────────────────────────────────────────────────

if [[ "$MODE" == "build" || "$MODE" == "all" ]]; then
    echo "=== Building AruviOS RV32 kernel ==="
    echo "    Target:   ${TARGET}"
    echo "    Features: ${FEATURES}"
    echo ""

    cargo +nightly build \
        --release \
        --features "${FEATURES}" \
        -Z build-std=core \
        -Z build-std-features=compiler-builtins-mem \
        -Z json-target-spec

    # Show binary size
    if command -v llvm-size &>/dev/null; then
        echo ""
        echo "=== Kernel size ==="
        llvm-size "$KERNEL_ELF"
    elif command -v riscv32-unknown-elf-size &>/dev/null; then
        echo ""
        echo "=== Kernel size ==="
        riscv32-unknown-elf-size "$KERNEL_ELF"
    else
        echo ""
        ls -lh "$KERNEL_ELF"
    fi

    echo ""
    echo "=== Build successful ==="
    echo "    ELF: ${KERNEL_ELF}"
    echo ""
    echo "=== To run interactively: ==="
    echo "    ./start.sh"
fi

# ── Run on QEMU ──────────────────────────────────────────────────────────

if [[ "$MODE" == "run" || "$MODE" == "all" ]]; then
    if [[ ! -f "$KERNEL_ELF" ]]; then
        echo "ERROR: Kernel ELF not found at ${KERNEL_ELF}"
        echo "       Run './build_rv32.sh build' first."
        exit 1
    fi

    # Check for QEMU
    if ! command -v qemu-system-riscv32 &>/dev/null; then
        echo "ERROR: qemu-system-riscv32 not found."
        echo "       Install with: brew install qemu"
        exit 1
    fi

    echo ""
    echo "=== Running on QEMU riscv32 virt ==="
    echo "    Press Ctrl-A then X to exit QEMU"
    echo ""

    qemu-system-riscv32 \
        -machine virt \
        -cpu rv32 \
        -m 128M \
        -bios none \
        -serial stdio \
        -display none \
        -monitor none \
        -kernel "$KERNEL_ELF"
fi
