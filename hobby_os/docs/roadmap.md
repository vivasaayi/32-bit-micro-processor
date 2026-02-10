# Hobby OS Roadmap

## Phase 1 (done in this scaffold)
- Bootable Rust kernel.
- VGA console output.
- PS/2 keyboard input.
- Command shell with utility registry.

## Phase 2
- Add timer interrupt and clock ticks.
- Add command history + line editing.
- Add static RAM-backed filesystem.

## Phase 3
- Add user-mode process model.
- Define syscall table (`write`, `exit`, `open`, `read`).
- Run C-compiled utility binaries from the shell.

## Phase 4
- Add ELF loader.
- Add tiny libc shim for utilities.
- Add package script to bundle utilities into disk image.
