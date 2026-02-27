# QEMU Verification Test for AruviX
# Optimized for QEMU 'virt' machine (RAM base 0x80000000)

.org 0x80000000
_start:
# UART0 MMIO address in QEMU 'virt' machine
LI t0, 0x10000000

# Print 'AruviX QEMU OK\n'
LI t1, 0x41 # 'A'
SB t1, 0(t0)
LI t1, 0x72 # 'r'
SB t1, 0(t0)
LI t1, 0x75 # 'u'
SB t1, 0(t0)
LI t1, 0x76 # 'v'
SB t1, 0(t0)
LI t1, 0x69 # 'i'
SB t1, 0(t0)
LI t1, 0x58 # 'X'
SB t1, 0(t0)
LI t1, 0x20 # ' '
SB t1, 0(t0)
LI t1, 0x51 # 'Q'
SB t1, 0(t0)
LI t1, 0x45 # 'E'
SB t1, 0(t0)
LI t1, 0x4D # 'M'
SB t1, 0(t0)
LI t1, 0x55 # 'U'
SB t1, 0(t0)
LI t1, 0x20 # ' '
SB t1, 0(t0)
LI t1, 0x4F # 'O'
SB t1, 0(t0)
LI t1, 0x4B # 'K'
SB t1, 0(t0)
LI t1, 0x0A # '\n'
SB t1, 0(t0)

# Perform a simple calculation
ADDI a0, zero, 10
ADDI a1, zero, 20
ADD  a2, a0, a1 # a2 = 30

# Exit QEMU by triggering an exception (EBREAK)
# In a real OS this would be a system call
EBREAK
