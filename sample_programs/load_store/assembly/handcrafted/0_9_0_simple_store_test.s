.global _start

.org 0x8000

_start:
addi x1, x0, 42
sw x1, 0x0100(x0)
addi x2, x0, 99
sw x2, 0x0104(x0)

lw x4, 0x0100(x0)
lw x5, 0x0104(x0)
ebreak