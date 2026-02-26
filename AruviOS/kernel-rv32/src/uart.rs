//! UART Driver for AruviOS RV32
//!
//! Supports two platforms via compile-time feature flags:
//!
//! ## QEMU virt (default) — NS16550A
//! Standard 16550A-compatible UART at 0x10000000.
//! Register layout: THR/RBR(+0), IER(+1), FCR(+2), LCR(+3), MCR(+4), LSR(+5)
//!
//! ## AruviX Hardware — Custom UART
//! Custom UART designed in uart.v at 0xF0000000.
//! Register layout: DATA(+0), STATUS(+1), CTRL(+2), BAUD_L(+3), BAUD_H(+4)
//!   STATUS bit 0 = TX ready, bit 1 = RX ready

use crate::platform;

// ─── NS16550A UART (QEMU virt) ─────────────────────────────────────────────

#[cfg(feature = "qemu-virt")]
mod hw {
    use super::platform;

    const THR: usize = 0; // Transmit Holding Register (write)
    const RBR: usize = 0; // Receive Buffer Register (read)
    const IER: usize = 1; // Interrupt Enable Register
    const FCR: usize = 2; // FIFO Control Register (write)
    const LCR: usize = 3; // Line Control Register
    const LSR: usize = 5; // Line Status Register

    const LSR_TX_EMPTY: u8 = 1 << 5; // THR is empty
    const LSR_RX_READY: u8 = 1 << 0; // Data available in RBR

    #[inline]
    fn base() -> *mut u8 {
        platform::UART_BASE as *mut u8
    }

    pub fn init() {
        unsafe {
            let b = base();
            // Disable all interrupts
            b.add(IER).write_volatile(0x00);
            // Enable FIFO, clear buffers, 1-byte trigger
            b.add(FCR).write_volatile(0x07);
            // 8 data bits, no parity, 1 stop bit (8N1)
            b.add(LCR).write_volatile(0x03);
        }
    }

    pub fn putc(c: u8) {
        unsafe {
            let b = base();
            // Spin until the transmit holding register is empty
            while b.add(LSR).read_volatile() & LSR_TX_EMPTY == 0 {}
            b.add(THR).write_volatile(c);
        }
    }

    pub fn getc() -> Option<u8> {
        unsafe {
            let b = base();
            if b.add(LSR).read_volatile() & LSR_RX_READY != 0 {
                Some(b.add(RBR).read_volatile())
            } else {
                None
            }
        }
    }
}

// ─── AruviX Custom UART (from processor/io/uart.v) ─────────────────────────

#[cfg(feature = "aruvix-hw")]
mod hw {
    use super::platform;

    // Register offsets matching uart.v
    const DATA: usize = 0;   // Data register (read/write)
    const STATUS: usize = 1; // Status register (read)
    const CTRL: usize = 2;   // Control register
    const BAUD_L: usize = 3; // Baud rate divisor low
    const BAUD_H: usize = 4; // Baud rate divisor high

    // Status register bits (from uart.v)
    const STATUS_TX_READY: u8 = 1 << 0;
    const STATUS_RX_READY: u8 = 1 << 1;

    // Control register bits
    const CTRL_TX_EN: u8 = 1 << 0;
    const CTRL_RX_EN: u8 = 1 << 1;

    #[inline]
    fn base() -> *mut u8 {
        platform::UART_BASE as *mut u8
    }

    pub fn init() {
        unsafe {
            let b = base();
            // Enable TX and RX
            b.add(CTRL).write_volatile(CTRL_TX_EN | CTRL_RX_EN);
            // Set baud rate divisor (e.g., for 115200 @ 50MHz: div = 434 = 0x01B2)
            b.add(BAUD_L).write_volatile(0xB2);
            b.add(BAUD_H).write_volatile(0x01);
        }
    }

    pub fn putc(c: u8) {
        unsafe {
            let b = base();
            // Spin until TX is ready
            while b.add(STATUS).read_volatile() & STATUS_TX_READY == 0 {}
            b.add(DATA).write_volatile(c);
        }
    }

    pub fn getc() -> Option<u8> {
        unsafe {
            let b = base();
            if b.add(STATUS).read_volatile() & STATUS_RX_READY != 0 {
                Some(b.add(DATA).read_volatile())
            } else {
                None
            }
        }
    }
}

// ─── Public API ─────────────────────────────────────────────────────────────

/// Initialize the UART hardware.
pub fn init() {
    hw::init();
}

/// Write a single byte to the UART.
pub fn putc(c: u8) {
    hw::putc(c);
}

/// Try to read a byte from the UART (non-blocking).
pub fn getc() -> Option<u8> {
    hw::getc()
}

/// Write a string to the UART.
pub fn puts(s: &str) {
    for byte in s.bytes() {
        if byte == b'\n' {
            putc(b'\r'); // Emit CR+LF for serial terminals
        }
        putc(byte);
    }
}

/// Print a 32-bit value in hexadecimal.
pub fn put_hex(val: u32) {
    const HEX: &[u8; 16] = b"0123456789ABCDEF";
    for i in (0..8).rev() {
        let nibble = ((val >> (i * 4)) & 0xF) as usize;
        putc(HEX[nibble]);
    }
}

/// Print a 32-bit unsigned decimal value.
pub fn put_dec(val: u32) {
    if val == 0 {
        putc(b'0');
        return;
    }

    let mut buf = [0u8; 10]; // max 10 digits for u32
    let mut idx = buf.len();
    let mut n = val;

    while n > 0 {
        idx -= 1;
        buf[idx] = b'0' + (n % 10) as u8;
        n /= 10;
    }

    for &b in &buf[idx..] {
        putc(b);
    }
}

/// Print a signed 32-bit decimal value.
pub fn put_i32(val: i32) {
    if val < 0 {
        putc(b'-');
        // Handle i32::MIN carefully
        if val == i32::MIN {
            puts("2147483648");
            return;
        }
        put_dec((-val) as u32);
    } else {
        put_dec(val as u32);
    }
}
