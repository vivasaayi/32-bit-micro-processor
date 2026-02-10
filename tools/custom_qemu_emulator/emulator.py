#!/usr/bin/env python3
"""Custom educational emulator for this repository's 32-bit assembly dialect.

This is intentionally small and traceable so it can be used as a learning tool
alongside QEMU/Spike/RTL simulations.
"""

from __future__ import annotations

import argparse
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, List, Optional, Tuple

REGISTER_COUNT = 32
MASK32 = 0xFFFFFFFF


class EmulatorError(RuntimeError):
    """Raised for parse or execution errors."""


@dataclass
class Flags:
    carry: bool = False
    zero: bool = False
    negative: bool = False
    overflow: bool = False


@dataclass
class Instruction:
    op: str
    args: List[str]
    line_no: int
    raw: str


class Custom32Emulator:
    def __init__(self, memory_size: int = 1024 * 1024) -> None:
        self.memory = bytearray(memory_size)
        self.registers = [0] * REGISTER_COUNT
        self.flags = Flags()
        self.pc = 0
        self.halted = False
        self.instruction_count = 0

        self.instructions: List[Instruction] = []
        self.labels: Dict[str, int] = {}

    @staticmethod
    def _clean_line(line: str) -> str:
        return line.split(";", 1)[0].strip()

    @staticmethod
    def _to_u32(value: int) -> int:
        return value & MASK32

    @staticmethod
    def _to_i32(value: int) -> int:
        value &= MASK32
        return value if value < 0x80000000 else value - 0x100000000

    @staticmethod
    def _parse_register(token: str) -> int:
        token = token.strip().upper()
        if not token.startswith("R"):
            raise EmulatorError(f"Expected register token, got '{token}'")
        try:
            idx = int(token[1:])
        except ValueError as exc:
            raise EmulatorError(f"Invalid register '{token}'") from exc
        if not 0 <= idx < REGISTER_COUNT:
            raise EmulatorError(f"Register out of range: {token}")
        return idx

    @staticmethod
    def _parse_immediate(token: str) -> int:
        token = token.strip()
        if token.startswith("#"):
            token = token[1:]
        return int(token, 0)

    def _parse_operand_address(self, token: str) -> int:
        token = token.strip()
        if token.upper().startswith("R"):
            return self.registers[self._parse_register(token)]
        if token in self.labels:
            return self.labels[token]
        return self._parse_immediate(token)

    def load_assembly_text(self, source: str) -> None:
        self.instructions.clear()
        self.labels.clear()

        # Pass 1: labels and normalized instruction text.
        for line_no, line in enumerate(source.splitlines(), start=1):
            cleaned = self._clean_line(line)
            if not cleaned:
                continue

            current = cleaned
            while ":" in current:
                maybe_label, rest = current.split(":", 1)
                label = maybe_label.strip()
                if not label:
                    break
                if label in self.labels:
                    raise EmulatorError(f"Duplicate label '{label}' at line {line_no}")
                self.labels[label] = len(self.instructions)
                current = rest.strip()
                if not current:
                    break

            if not current:
                continue

            if current.startswith("."):
                # Keep parser permissive for common assembler directives.
                # Current emulator executes instructions only, so directives
                # like .org/.text/.data are ignored.
                continue

            if " " in current:
                op, arg_text = current.split(None, 1)
                args = [a.strip() for a in arg_text.split(",") if a.strip()]
            else:
                op, args = current, []
            self.instructions.append(
                Instruction(op=op.upper(), args=args, line_no=line_no, raw=cleaned)
            )

    def load_assembly_file(self, path: Path) -> None:
        self.load_assembly_text(path.read_text())

    def _read_word(self, addr: int) -> int:
        if addr % 4 != 0:
            raise EmulatorError(f"Unaligned LOAD at 0x{addr:X}")
        if not 0 <= addr <= len(self.memory) - 4:
            raise EmulatorError(f"LOAD out of range at 0x{addr:X}")
        return int.from_bytes(self.memory[addr : addr + 4], "little")

    def _write_word(self, addr: int, value: int) -> None:
        if addr % 4 != 0:
            raise EmulatorError(f"Unaligned STORE at 0x{addr:X}")
        if not 0 <= addr <= len(self.memory) - 4:
            raise EmulatorError(f"STORE out of range at 0x{addr:X}")
        self.memory[addr : addr + 4] = self._to_u32(value).to_bytes(4, "little")

    def _set_arith_flags(self, result: int, carry: bool, overflow: bool) -> None:
        self.flags.carry = carry
        self.flags.overflow = overflow
        self.flags.zero = (result & MASK32) == 0
        self.flags.negative = bool(result & 0x80000000)

    def _set_logic_flags(self, result: int) -> None:
        self.flags.carry = False
        self.flags.overflow = False
        self.flags.zero = (result & MASK32) == 0
        self.flags.negative = bool(result & 0x80000000)

    def _write_reg(self, reg_idx: int, value: int) -> None:
        # Match RISC convention in this repo: R0 is hardwired to zero.
        if reg_idx == 0:
            return
        self.registers[reg_idx] = self._to_u32(value)

    def _jump_to(self, target_token: str) -> None:
        if target_token in self.labels:
            self.pc = self.labels[target_token]
            return
        # Support immediate jump-to-instruction-index for quick experiments.
        self.pc = self._parse_immediate(target_token)

    def step(self, trace: bool = False) -> None:
        if self.halted:
            return
        if not 0 <= self.pc < len(self.instructions):
            raise EmulatorError(f"PC out of range: {self.pc}")

        inst = self.instructions[self.pc]
        next_pc = self.pc + 1
        op, args = inst.op, inst.args

        if trace:
            print(f"pc={self.pc:04d} | {inst.raw}")

        if op == "LOADI":
            rd, imm = self._parse_register(args[0]), self._parse_operand_address(args[1])
            self._write_reg(rd, imm)
            self._set_logic_flags(imm)
        elif op == "LOAD":
            rd = self._parse_register(args[0])
            addr = self._parse_operand_address(args[1])
            val = self._read_word(addr)
            self._write_reg(rd, val)
            self._set_logic_flags(val)
        elif op == "STORE":
            rs = self._parse_register(args[0])
            addr = self._parse_operand_address(args[1])
            self._write_word(addr, self.registers[rs])
        elif op == "ADD":
            rd, rs1, rs2 = map(self._parse_register, args)
            a, b = self.registers[rs1], self.registers[rs2]
            full = a + b
            result = self._to_u32(full)
            carry = full > MASK32
            overflow = (((a ^ result) & (b ^ result)) & 0x80000000) != 0
            self._write_reg(rd, result)
            self._set_arith_flags(result, carry, overflow)
        elif op == "ADDI":
            rd, rs1 = map(self._parse_register, args[:2])
            imm = self._parse_operand_address(args[2])
            a = self.registers[rs1]
            full = a + imm
            result = self._to_u32(full)
            carry = full > MASK32
            overflow = (((a ^ result) & (imm ^ result)) & 0x80000000) != 0
            self._write_reg(rd, result)
            self._set_arith_flags(result, carry, overflow)
        elif op == "SUB":
            rd, rs1, rs2 = map(self._parse_register, args)
            a, b = self.registers[rs1], self.registers[rs2]
            full = (a - b) & 0x1FFFFFFFF
            result = self._to_u32(full)
            carry = a >= b
            overflow = (((a ^ b) & (a ^ result)) & 0x80000000) != 0
            self._write_reg(rd, result)
            self._set_arith_flags(result, carry, overflow)
        elif op == "SUBI":
            rd, rs1 = map(self._parse_register, args[:2])
            imm = self._parse_operand_address(args[2])
            a = self.registers[rs1]
            b = self._to_u32(imm)
            result = self._to_u32(a - b)
            carry = a >= b
            overflow = (((a ^ b) & (a ^ result)) & 0x80000000) != 0
            self._write_reg(rd, result)
            self._set_arith_flags(result, carry, overflow)
        elif op == "AND":
            rd, rs1, rs2 = map(self._parse_register, args)
            result = self.registers[rs1] & self.registers[rs2]
            self._write_reg(rd, result)
            self._set_logic_flags(result)
        elif op == "OR":
            rd, rs1, rs2 = map(self._parse_register, args)
            result = self.registers[rs1] | self.registers[rs2]
            self._write_reg(rd, result)
            self._set_logic_flags(result)
        elif op == "XOR":
            rd, rs1, rs2 = map(self._parse_register, args)
            result = self.registers[rs1] ^ self.registers[rs2]
            self._write_reg(rd, result)
            self._set_logic_flags(result)
        elif op == "SHL":
            rd, rs1 = map(self._parse_register, args[:2])
            sh = self._parse_operand_address(args[2]) & 31
            result = self._to_u32(self.registers[rs1] << sh)
            self._write_reg(rd, result)
            self._set_logic_flags(result)
        elif op == "SHR":
            rd, rs1 = map(self._parse_register, args[:2])
            sh = self._parse_operand_address(args[2]) & 31
            result = self.registers[rs1] >> sh
            self._write_reg(rd, result)
            self._set_logic_flags(result)
        elif op == "CMP":
            rs1, rs2 = map(self._parse_register, args)
            a, b = self.registers[rs1], self.registers[rs2]
            result = self._to_u32(a - b)
            carry = a >= b
            overflow = (((a ^ b) & (a ^ result)) & 0x80000000) != 0
            self._set_arith_flags(result, carry, overflow)
        elif op == "JMP":
            self._jump_to(args[0])
            next_pc = self.pc
        elif op == "JZ":
            if self.flags.zero:
                self._jump_to(args[0])
                next_pc = self.pc
        elif op == "JNZ":
            if not self.flags.zero:
                self._jump_to(args[0])
                next_pc = self.pc
        elif op == "JC":
            if self.flags.carry:
                self._jump_to(args[0])
                next_pc = self.pc
        elif op == "JNC":
            if not self.flags.carry:
                self._jump_to(args[0])
                next_pc = self.pc
        elif op == "JLT":
            if self.flags.negative:
                self._jump_to(args[0])
                next_pc = self.pc
        elif op == "JGE":
            if not self.flags.negative:
                self._jump_to(args[0])
                next_pc = self.pc
        elif op == "JLE":
            if self.flags.zero or self.flags.negative:
                self._jump_to(args[0])
                next_pc = self.pc
        elif op == "HALT":
            self.halted = True
        else:
            raise EmulatorError(
                f"Unsupported opcode '{op}' at line {inst.line_no}: {inst.raw}"
            )

        self.pc = next_pc
        self.registers[0] = 0
        self.instruction_count += 1

    def run(self, max_steps: int = 1_000_000, trace: bool = False) -> None:
        while not self.halted and self.instruction_count < max_steps:
            self.step(trace=trace)
        if not self.halted:
            raise EmulatorError(
                f"Execution did not halt after {max_steps} steps (possible infinite loop)"
            )

    def summary(self) -> str:
        nz_regs: List[Tuple[int, int]] = [
            (i, val) for i, val in enumerate(self.registers) if val != 0
        ]
        regs = " ".join(f"R{i}=0x{v:08X}" for i, v in nz_regs[:12])
        if len(nz_regs) > 12:
            regs += " ..."
        return (
            f"halted={self.halted} steps={self.instruction_count} pc={self.pc} "
            f"flags(C={int(self.flags.carry)} Z={int(self.flags.zero)} "
            f"N={int(self.flags.negative)} V={int(self.flags.overflow)}) {regs}"
        )


def main() -> None:
    parser = argparse.ArgumentParser(description="Custom educational 32-bit emulator")
    parser.add_argument("assembly_file", type=Path, help="Assembly source file")
    parser.add_argument("--max-steps", type=int, default=1_000_000)
    parser.add_argument("--trace", action="store_true", help="Print executed instructions")
    parser.add_argument(
        "--dump-addr",
        type=lambda x: int(x, 0),
        default=0x2000,
        help="Word address to print after execution (default: 0x2000)",
    )
    args = parser.parse_args()

    emu = Custom32Emulator()
    emu.load_assembly_file(args.assembly_file)
    emu.run(max_steps=args.max_steps, trace=args.trace)

    dumped = emu._read_word(args.dump_addr)
    print(emu.summary())
    print(f"mem[0x{args.dump_addr:08X}] = 0x{dumped:08X} ({Custom32Emulator._to_i32(dumped)})")


if __name__ == "__main__":
    main()
