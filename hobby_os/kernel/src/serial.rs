use x86_64::instructions::port::Port;

const COM1_BASE: u16 = 0x3F8;

pub fn init() {
    unsafe {
        let mut interrupt_enable = Port::<u8>::new(COM1_BASE + 1);
        let mut line_control = Port::<u8>::new(COM1_BASE + 3);
        let mut divisor_lsb = Port::<u8>::new(COM1_BASE + 0);
        let mut divisor_msb = Port::<u8>::new(COM1_BASE + 1);
        let mut fifo_control = Port::<u8>::new(COM1_BASE + 2);
        let mut modem_control = Port::<u8>::new(COM1_BASE + 4);

        interrupt_enable.write(0x00);
        line_control.write(0x80);
        divisor_lsb.write(0x03);
        divisor_msb.write(0x00);
        line_control.write(0x03);
        fifo_control.write(0xC7);
        modem_control.write(0x0B);
    }
}

pub fn print(text: &str) {
    for b in text.bytes() {
        write_byte(b);
    }
}

pub fn print_line(text: &str) {
    print(text);
    print("\n");
}

pub fn try_read_char() -> Option<char> {
    let has_data = unsafe {
        let mut line_status = Port::<u8>::new(COM1_BASE + 5);
        line_status.read() & 0x01 != 0
    };

    if !has_data {
        return None;
    }

    let byte = unsafe {
        let mut data_port = Port::<u8>::new(COM1_BASE);
        data_port.read()
    };

    match byte {
        b'\r' => Some('\n'),
        0x08 | 0x7f => Some('\u{8}'),
        0x20..=0x7e | b'\n' => Some(byte as char),
        _ => None,
    }
}

fn write_byte(byte: u8) {
    unsafe {
        let mut line_status = Port::<u8>::new(COM1_BASE + 5);
        while line_status.read() & 0x20 == 0 {}

        let mut data_port = Port::<u8>::new(COM1_BASE);
        data_port.write(byte);
    }
}
