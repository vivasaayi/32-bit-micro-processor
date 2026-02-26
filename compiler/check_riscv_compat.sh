#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

TESTS=(
  "test_simple.c"
  "test_bool.c"
  "test_switch.c"
)

for test_file in "${TESTS[@]}"; do
  asm_file="$TMP_DIR/${test_file%.c}.s"
  obj_file="$TMP_DIR/${test_file%.c}.o"

  "$ROOT_DIR/ccompiler" "$ROOT_DIR/$test_file" -o "$asm_file" >/dev/null
  clang -target riscv32 -c "$asm_file" -o "$obj_file"
  echo "PASS: $test_file -> RISC-V assembly accepted"
done

echo "All compatibility checks passed."
