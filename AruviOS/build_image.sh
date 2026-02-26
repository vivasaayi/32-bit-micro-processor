#!/bin/bash

# Build AruviOS with custom bootloader

set -e

echo "Building kernel..."
cd kernel
cargo +nightly build \
    -Z build-std=core,compiler_builtins \
    -Z build-std-features=compiler-builtins-mem \
    -Z json-target-spec \
    --target x86_64-aruvios.json
echo "Extracting flat binary..."
OBJCOPY=~/.rustup/toolchains/nightly-aarch64-apple-darwin/lib/rustlib/aarch64-apple-darwin/bin/llvm-objcopy
$OBJCOPY -O binary \
    ../target/x86_64-aruvios/debug/aruvix_hobby_os \
    ../kernel.bin
cd ..

echo "Assembling bootloader..."
nasm -f bin bootloader/bootloader.asm -o bootloader.bin

echo "Creating bootable disk image..."
# Create a 2MB hard disk image (large enough for bootloader + 221 sector kernel)
dd if=/dev/zero of=aruvix_os.img bs=512 count=4096

# Write bootloader to MBR (sector 0)
dd if=bootloader.bin of=aruvix_os.img conv=notrunc

# Write kernel starting at sector 1 (LBA 1)
dd if=kernel.bin of=aruvix_os.img bs=512 seek=1 conv=notrunc

echo "Bootable image created: aruvix_os.img (kernel entry at 0x100000)"
echo "Run with: qemu-system-x86_64 -drive format=raw,file=aruvix_os.img -serial file:/tmp/serial.txt"