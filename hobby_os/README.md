# Hobby OS (VirtualBox-friendly, Rust kernel)

This folder is a self-contained starter operating system project with a **simple shell**, a **utility registry**, and a build path that can produce a bootable image.

## Folder structure

```
hobby_os/
├── build/
│   └── Makefile                 # Build/run helper commands
├── docs/
│   └── roadmap.md               # Suggested evolution plan
├── kernel/
│   ├── .cargo/config.toml       # Bare-metal target
│   ├── Cargo.toml               # Kernel crate dependencies
│   ├── rust-toolchain.toml      # Toolchain components
│   └── src/
│       ├── main.rs              # Kernel entrypoint + panic handler
│       ├── shell.rs             # Simple shell + command parsing
│       ├── keyboard.rs          # PS/2 scancode input
│       └── vga.rs               # VGA text output
└── user_utils/
    └── src/
        ├── echo.c               # Example C utility skeleton
        └── sum.c                # Example C utility skeleton
```

## What this already does

- Boots to VGA text mode.
- Prints a shell prompt.
- Accepts keyboard input.
- Supports:
  - `help`
  - `ls` (lists registered utilities)
  - `run <utility> [args]`
  - `clear`
- Includes registered demo utilities:
  - `echo`
  - `sum`
  - `about`

## Build and run

```bash
cd hobby_os/build
make image
make run
```

## Run in VirtualBox

1. Build image (`make image`).
2. Convert raw image to VDI:
   ```bash
   VBoxManage convertfromraw ../kernel/target/x86_64-unknown-none/debug/bootimage-aruvix_hobby_os.bin hobby_os.vdi --format VDI
   ```
3. Create VM (Other/Unknown OS).
4. Attach `hobby_os.vdi` as primary disk.
5. Boot VM.

## Next milestone for C utilities

Right now utility execution is in-kernel Rust function dispatch. The next step is:

1. Define a tiny utility ABI (`int main(int argc, char** argv)` style).
2. Compile C utilities into flat binaries.
3. Add a tiny in-memory filesystem or ROM loader.
4. Extend `run` to load binary utility image and jump to entrypoint in user mode.

This gives the full cycle you asked for: list utilities, execute utilities, and keep extending toward a small but real OS.
