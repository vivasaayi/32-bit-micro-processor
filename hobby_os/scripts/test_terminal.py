#!/usr/bin/env python3
import os
import selectors
import shutil
import subprocess
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
IMAGE = ROOT / "kernel/target/x86_64-unknown-none/debug/bootimage-aruvix_hobby_os.bin"


def main() -> int:
    if not shutil.which("qemu-system-x86_64"):
        print("[SKIP] qemu-system-x86_64 not found")
        return 0

    if not IMAGE.exists():
        print(f"[FAIL] boot image not found: {IMAGE}")
        return 1

    cmd = [
        "qemu-system-x86_64",
        "-drive",
        f"format=raw,file={IMAGE}",
        "-nographic",
        "-serial",
        "stdio",
        "-monitor",
        "none",
        "-display",
        "none",
        "-no-reboot",
    ]

    proc = subprocess.Popen(
        cmd,
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        cwd=ROOT,
        env={**os.environ, "LC_ALL": "C"},
        bufsize=1,
    )

    sel = selectors.DefaultSelector()
    assert proc.stdout is not None
    sel.register(proc.stdout, selectors.EVENT_READ)

    def write_line(line: str) -> None:
        assert proc.stdin is not None
        proc.stdin.write(line)
        proc.stdin.flush()

    output = ""
    try:
        time.sleep(2.0)
        for line in [
            "help\n",
            "ls\n",
            "run echo smoke_test\n",
            "run sum 7 35\n",
            "run noexist\n",
        ]:
            write_line(line)
            time.sleep(0.4)

        deadline = time.time() + 6.0
        while time.time() < deadline:
            events = sel.select(timeout=0.25)
            for key, _ in events:
                chunk = key.fileobj.read()  # line-buffered chunks
                if not chunk:
                    continue
                output += chunk

        required = [
            "AruviX HobbyOS (Rust)",
            "Builtins: help, ls, run <utility>, clear",
            "echo",
            "sum",
            "about",
            "smoke_test",
            "result:",
            "42",
            "utility not found",
        ]

        missing = [item for item in required if item not in output]
        if missing:
            print(output)
            print(f"[FAIL] missing expected output: {missing}")
            return 1

        print("[PASS] terminal smoke test passed")
        return 0
    finally:
        proc.kill()


if __name__ == "__main__":
    sys.exit(main())
