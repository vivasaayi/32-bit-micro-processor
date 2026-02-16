#!/usr/bin/env python3
import os
import shutil
import subprocess
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
IMAGE = ROOT / "kernel/target/x86_64-unknown-none/debug/bootimage-aruvix_hobby_os.bin"


def read_available(proc: subprocess.Popen[str], timeout_s: float = 0.2) -> str:
    if proc.stdout is None:
        return ""

    fd = proc.stdout.fileno()
    data = []
    end = time.time() + timeout_s

    while time.time() < end:
        try:
            chunk = os.read(fd, 4096)
            if not chunk:
                break
            data.append(chunk.decode(errors="replace"))
        except BlockingIOError:
            time.sleep(0.03)

    return "".join(data)


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
        text=False,
        cwd=ROOT,
        env={**os.environ, "LC_ALL": "C"},
        bufsize=0,
    )

    assert proc.stdout is not None
    os.set_blocking(proc.stdout.fileno(), False)

    def write_line(line: str) -> None:
        if proc.stdin is None:
            return
        proc.stdin.write(line.encode())
        proc.stdin.flush()

    output = ""
    try:
        time.sleep(2.0)
        output += read_available(proc, 0.8)

        for line in [
            "help\n",
            "ls\n",
            "run echo smoke_test\n",
            "run sum 7 35\n",
            "run noexist\n",
        ]:
            write_line(line)
            time.sleep(0.35)
            output += read_available(proc, 0.5)

        output += read_available(proc, 2.5)

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
