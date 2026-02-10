use std::collections::HashMap;

const REGISTER_COUNT: usize = 32;
const MASK32: u64 = 0xFFFF_FFFF;

#[derive(Debug, Clone, Copy, Default)]
pub struct Flags {
    pub carry: bool,
    pub zero: bool,
    pub negative: bool,
    pub overflow: bool,
}

#[derive(Debug, Clone)]
pub struct Instruction {
    pub op: String,
    pub args: Vec<String>,
    pub line_no: usize,
    pub raw: String,
}

#[derive(Debug)]
pub enum EmulatorError {
    Parse(String),
    Exec(String),
}

impl std::fmt::Display for EmulatorError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Self::Parse(msg) | Self::Exec(msg) => write!(f, "{msg}"),
        }
    }
}

impl std::error::Error for EmulatorError {}

pub struct Custom32Emulator {
    pub memory: Vec<u8>,
    pub registers: [u32; REGISTER_COUNT],
    pub flags: Flags,
    pub pc: usize,
    pub halted: bool,
    pub instruction_count: usize,
    pub instructions: Vec<Instruction>,
    pub labels: HashMap<String, usize>,
}

impl Default for Custom32Emulator {
    fn default() -> Self {
        Self::new(1024 * 1024)
    }
}

impl Custom32Emulator {
    pub fn new(memory_size: usize) -> Self {
        Self {
            memory: vec![0; memory_size],
            registers: [0; REGISTER_COUNT],
            flags: Flags::default(),
            pc: 0,
            halted: false,
            instruction_count: 0,
            instructions: Vec::new(),
            labels: HashMap::new(),
        }
    }

    fn clean_line(line: &str) -> String {
        line.split(';').next().unwrap_or_default().trim().to_string()
    }

    fn parse_register(token: &str) -> Result<usize, EmulatorError> {
        let tok = token.trim().to_uppercase();
        if !tok.starts_with('R') {
            return Err(EmulatorError::Parse(format!("Expected register token, got '{tok}'")));
        }
        let idx = tok[1..]
            .parse::<usize>()
            .map_err(|_| EmulatorError::Parse(format!("Invalid register '{tok}'")))?;
        if idx >= REGISTER_COUNT {
            return Err(EmulatorError::Parse(format!("Register out of range: {tok}")));
        }
        Ok(idx)
    }

    fn parse_imm(token: &str) -> Result<i64, EmulatorError> {
        let tok = token.trim().trim_start_matches('#');
        if let Some(rest) = tok.strip_prefix("0x") {
            i64::from_str_radix(rest, 16)
                .map_err(|_| EmulatorError::Parse(format!("Invalid immediate '{token}'")))
        } else if let Some(rest) = tok.strip_prefix("-0x") {
            i64::from_str_radix(rest, 16)
                .map(|v| -v)
                .map_err(|_| EmulatorError::Parse(format!("Invalid immediate '{token}'")))
        } else {
            tok.parse::<i64>()
                .map_err(|_| EmulatorError::Parse(format!("Invalid immediate '{token}'")))
        }
    }

    fn parse_operand_address(&self, token: &str) -> Result<u32, EmulatorError> {
        let trimmed = token.trim();
        if trimmed.to_uppercase().starts_with('R') {
            let idx = Self::parse_register(trimmed)?;
            return Ok(self.registers[idx]);
        }
        if let Some(target) = self.labels.get(trimmed) {
            return Ok(*target as u32);
        }
        Ok(Self::parse_imm(trimmed)? as u32)
    }

    pub fn load_assembly_text(&mut self, source: &str) -> Result<(), EmulatorError> {
        self.instructions.clear();
        self.labels.clear();
        self.pc = 0;
        self.halted = false;
        self.instruction_count = 0;

        for (line_idx, line) in source.lines().enumerate() {
            let line_no = line_idx + 1;
            let cleaned = Self::clean_line(line);
            if cleaned.is_empty() {
                continue;
            }

            let mut current = cleaned.clone();
            while let Some((label, rest)) = current.split_once(':') {
                let lbl = label.trim();
                if lbl.is_empty() {
                    break;
                }
                if self.labels.contains_key(lbl) {
                    return Err(EmulatorError::Parse(format!(
                        "Duplicate label '{lbl}' at line {line_no}"
                    )));
                }
                self.labels.insert(lbl.to_string(), self.instructions.len());
                current = rest.trim().to_string();
                if current.is_empty() {
                    break;
                }
            }

            if current.is_empty() || current.starts_with('.') {
                continue;
            }

            let (op, args) = if let Some((opcode, arg_text)) = current.split_once(char::is_whitespace)
            {
                let parsed = arg_text
                    .split(',')
                    .map(|a| a.trim())
                    .filter(|a| !a.is_empty())
                    .map(ToString::to_string)
                    .collect::<Vec<_>>();
                (opcode.trim().to_uppercase(), parsed)
            } else {
                (current.trim().to_uppercase(), Vec::new())
            };

            self.instructions.push(Instruction {
                op,
                args,
                line_no,
                raw: cleaned,
            });
        }

        Ok(())
    }

    pub fn load_assembly_file<P: AsRef<std::path::Path>>(
        &mut self,
        path: P,
    ) -> Result<(), EmulatorError> {
        let src = std::fs::read_to_string(path)
            .map_err(|e| EmulatorError::Parse(format!("Failed to read assembly file: {e}")))?;
        self.load_assembly_text(&src)
    }

    pub fn read_word(&self, addr: u32) -> Result<u32, EmulatorError> {
        let a = addr as usize;
        if a % 4 != 0 {
            return Err(EmulatorError::Exec(format!("Unaligned LOAD at 0x{a:X}")));
        }
        if a + 4 > self.memory.len() {
            return Err(EmulatorError::Exec(format!("LOAD out of range at 0x{a:X}")));
        }
        Ok(u32::from_le_bytes(self.memory[a..a + 4].try_into().unwrap()))
    }

    pub fn write_word(&mut self, addr: u32, value: u32) -> Result<(), EmulatorError> {
        let a = addr as usize;
        if a % 4 != 0 {
            return Err(EmulatorError::Exec(format!("Unaligned STORE at 0x{a:X}")));
        }
        if a + 4 > self.memory.len() {
            return Err(EmulatorError::Exec(format!("STORE out of range at 0x{a:X}")));
        }
        self.memory[a..a + 4].copy_from_slice(&value.to_le_bytes());
        Ok(())
    }

    fn set_arith_flags(&mut self, result: u32, carry: bool, overflow: bool) {
        self.flags.carry = carry;
        self.flags.overflow = overflow;
        self.flags.zero = result == 0;
        self.flags.negative = (result & 0x8000_0000) != 0;
    }

    fn set_logic_flags(&mut self, result: u32) {
        self.flags.carry = false;
        self.flags.overflow = false;
        self.flags.zero = result == 0;
        self.flags.negative = (result & 0x8000_0000) != 0;
    }

    fn write_reg(&mut self, reg: usize, value: u32) {
        if reg != 0 {
            self.registers[reg] = value;
        }
    }

    fn jump_to(&mut self, target: &str) -> Result<(), EmulatorError> {
        if let Some(pc) = self.labels.get(target) {
            self.pc = *pc;
            return Ok(());
        }
        let idx = Self::parse_imm(target)?;
        if idx < 0 {
            return Err(EmulatorError::Exec(format!("Negative jump target: {idx}")));
        }
        self.pc = idx as usize;
        Ok(())
    }

    fn ensure_args(inst: &Instruction, want: usize) -> Result<(), EmulatorError> {
        if inst.args.len() != want {
            return Err(EmulatorError::Exec(format!(
                "Wrong arg count for {} at line {}: expected {}, got {}",
                inst.op,
                inst.line_no,
                want,
                inst.args.len()
            )));
        }
        Ok(())
    }

    pub fn step(&mut self, trace: bool) -> Result<(), EmulatorError> {
        if self.halted {
            return Ok(());
        }
        if self.pc >= self.instructions.len() {
            return Err(EmulatorError::Exec(format!("PC out of range: {}", self.pc)));
        }

        let inst = self.instructions[self.pc].clone();
        let mut next_pc = self.pc + 1;

        if trace {
            println!("pc={:04} | {}", self.pc, inst.raw);
        }

        match inst.op.as_str() {
            "LOADI" => {
                Self::ensure_args(&inst, 2)?;
                let rd = Self::parse_register(&inst.args[0])?;
                let imm = self.parse_operand_address(&inst.args[1])?;
                self.write_reg(rd, imm);
                self.set_logic_flags(imm);
            }
            "LOAD" => {
                Self::ensure_args(&inst, 2)?;
                let rd = Self::parse_register(&inst.args[0])?;
                let addr = self.parse_operand_address(&inst.args[1])?;
                let val = self.read_word(addr)?;
                self.write_reg(rd, val);
                self.set_logic_flags(val);
            }
            "STORE" => {
                Self::ensure_args(&inst, 2)?;
                let rs = Self::parse_register(&inst.args[0])?;
                let addr = self.parse_operand_address(&inst.args[1])?;
                self.write_word(addr, self.registers[rs])?;
            }
            "ADD" => {
                Self::ensure_args(&inst, 3)?;
                let rd = Self::parse_register(&inst.args[0])?;
                let rs1 = Self::parse_register(&inst.args[1])?;
                let rs2 = Self::parse_register(&inst.args[2])?;
                let a = self.registers[rs1] as u64;
                let b = self.registers[rs2] as u64;
                let full = a + b;
                let result = (full & MASK32) as u32;
                let carry = full > MASK32;
                let overflow = (((a as u32 ^ result) & (b as u32 ^ result)) & 0x8000_0000) != 0;
                self.write_reg(rd, result);
                self.set_arith_flags(result, carry, overflow);
            }
            "ADDI" => {
                Self::ensure_args(&inst, 3)?;
                let rd = Self::parse_register(&inst.args[0])?;
                let rs1 = Self::parse_register(&inst.args[1])?;
                let imm = self.parse_operand_address(&inst.args[2])? as u64;
                let a = self.registers[rs1] as u64;
                let full = a + imm;
                let result = (full & MASK32) as u32;
                let carry = full > MASK32;
                let overflow = (((a as u32 ^ result) & (imm as u32 ^ result)) & 0x8000_0000) != 0;
                self.write_reg(rd, result);
                self.set_arith_flags(result, carry, overflow);
            }
            "SUB" => {
                Self::ensure_args(&inst, 3)?;
                let rd = Self::parse_register(&inst.args[0])?;
                let rs1 = Self::parse_register(&inst.args[1])?;
                let rs2 = Self::parse_register(&inst.args[2])?;
                let a = self.registers[rs1];
                let b = self.registers[rs2];
                let result = a.wrapping_sub(b);
                let carry = a >= b;
                let overflow = (((a ^ b) & (a ^ result)) & 0x8000_0000) != 0;
                self.write_reg(rd, result);
                self.set_arith_flags(result, carry, overflow);
            }
            "SUBI" => {
                Self::ensure_args(&inst, 3)?;
                let rd = Self::parse_register(&inst.args[0])?;
                let rs1 = Self::parse_register(&inst.args[1])?;
                let imm = self.parse_operand_address(&inst.args[2])?;
                let a = self.registers[rs1];
                let result = a.wrapping_sub(imm);
                let carry = a >= imm;
                let overflow = (((a ^ imm) & (a ^ result)) & 0x8000_0000) != 0;
                self.write_reg(rd, result);
                self.set_arith_flags(result, carry, overflow);
            }
            "AND" => {
                Self::ensure_args(&inst, 3)?;
                let rd = Self::parse_register(&inst.args[0])?;
                let rs1 = Self::parse_register(&inst.args[1])?;
                let rs2 = Self::parse_register(&inst.args[2])?;
                let result = self.registers[rs1] & self.registers[rs2];
                self.write_reg(rd, result);
                self.set_logic_flags(result);
            }
            "OR" => {
                Self::ensure_args(&inst, 3)?;
                let rd = Self::parse_register(&inst.args[0])?;
                let rs1 = Self::parse_register(&inst.args[1])?;
                let rs2 = Self::parse_register(&inst.args[2])?;
                let result = self.registers[rs1] | self.registers[rs2];
                self.write_reg(rd, result);
                self.set_logic_flags(result);
            }
            "XOR" => {
                Self::ensure_args(&inst, 3)?;
                let rd = Self::parse_register(&inst.args[0])?;
                let rs1 = Self::parse_register(&inst.args[1])?;
                let rs2 = Self::parse_register(&inst.args[2])?;
                let result = self.registers[rs1] ^ self.registers[rs2];
                self.write_reg(rd, result);
                self.set_logic_flags(result);
            }
            "SHL" => {
                Self::ensure_args(&inst, 3)?;
                let rd = Self::parse_register(&inst.args[0])?;
                let rs1 = Self::parse_register(&inst.args[1])?;
                let sh = (self.parse_operand_address(&inst.args[2])? & 31) as u32;
                let result = self.registers[rs1].wrapping_shl(sh);
                self.write_reg(rd, result);
                self.set_logic_flags(result);
            }
            "SHR" => {
                Self::ensure_args(&inst, 3)?;
                let rd = Self::parse_register(&inst.args[0])?;
                let rs1 = Self::parse_register(&inst.args[1])?;
                let sh = (self.parse_operand_address(&inst.args[2])? & 31) as u32;
                let result = self.registers[rs1].wrapping_shr(sh);
                self.write_reg(rd, result);
                self.set_logic_flags(result);
            }
            "CMP" => {
                Self::ensure_args(&inst, 2)?;
                let rs1 = Self::parse_register(&inst.args[0])?;
                let rs2 = Self::parse_register(&inst.args[1])?;
                let a = self.registers[rs1];
                let b = self.registers[rs2];
                let result = a.wrapping_sub(b);
                let carry = a >= b;
                let overflow = (((a ^ b) & (a ^ result)) & 0x8000_0000) != 0;
                self.set_arith_flags(result, carry, overflow);
            }
            "JMP" => {
                Self::ensure_args(&inst, 1)?;
                self.jump_to(&inst.args[0])?;
                next_pc = self.pc;
            }
            "JZ" => {
                Self::ensure_args(&inst, 1)?;
                if self.flags.zero {
                    self.jump_to(&inst.args[0])?;
                    next_pc = self.pc;
                }
            }
            "JNZ" => {
                Self::ensure_args(&inst, 1)?;
                if !self.flags.zero {
                    self.jump_to(&inst.args[0])?;
                    next_pc = self.pc;
                }
            }
            "JC" => {
                Self::ensure_args(&inst, 1)?;
                if self.flags.carry {
                    self.jump_to(&inst.args[0])?;
                    next_pc = self.pc;
                }
            }
            "JNC" => {
                Self::ensure_args(&inst, 1)?;
                if !self.flags.carry {
                    self.jump_to(&inst.args[0])?;
                    next_pc = self.pc;
                }
            }
            "JLT" => {
                Self::ensure_args(&inst, 1)?;
                if self.flags.negative {
                    self.jump_to(&inst.args[0])?;
                    next_pc = self.pc;
                }
            }
            "JGE" => {
                Self::ensure_args(&inst, 1)?;
                if !self.flags.negative {
                    self.jump_to(&inst.args[0])?;
                    next_pc = self.pc;
                }
            }
            "JLE" => {
                Self::ensure_args(&inst, 1)?;
                if self.flags.zero || self.flags.negative {
                    self.jump_to(&inst.args[0])?;
                    next_pc = self.pc;
                }
            }
            "HALT" => {
                Self::ensure_args(&inst, 0)?;
                self.halted = true;
            }
            _ => {
                return Err(EmulatorError::Exec(format!(
                    "Unsupported opcode '{}' at line {}: {}",
                    inst.op, inst.line_no, inst.raw
                )))
            }
        }

        self.pc = next_pc;
        self.registers[0] = 0;
        self.instruction_count += 1;
        Ok(())
    }

    pub fn run(&mut self, max_steps: usize, trace: bool) -> Result<(), EmulatorError> {
        while !self.halted && self.instruction_count < max_steps {
            self.step(trace)?;
        }
        if !self.halted {
            return Err(EmulatorError::Exec(format!(
                "Execution did not halt after {max_steps} steps"
            )));
        }
        Ok(())
    }

    pub fn summary(&self) -> String {
        let mut pairs = Vec::new();
        for (i, v) in self.registers.iter().enumerate() {
            if *v != 0 {
                pairs.push((i, *v));
            }
        }
        let mut regs = pairs
            .iter()
            .take(12)
            .map(|(i, v)| format!("R{i}=0x{v:08X}"))
            .collect::<Vec<_>>()
            .join(" ");
        if pairs.len() > 12 {
            regs.push_str(" ...");
        }
        format!(
            "halted={} steps={} pc={} flags(C={} Z={} N={} V={}) {}",
            self.halted,
            self.instruction_count,
            self.pc,
            self.flags.carry as u8,
            self.flags.zero as u8,
            self.flags.negative as u8,
            self.flags.overflow as u8,
            regs
        )
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn run_program(asm: &str) -> Custom32Emulator {
        let mut emu = Custom32Emulator::default();
        emu.load_assembly_text(asm).unwrap();
        emu.run(10_000, false).unwrap();
        emu
    }

    #[test]
    fn sum_loop() {
        let emu = run_program(
            r#"
            LOADI R1, #10
            LOADI R2, #0
        LOOP:
            ADD R2, R2, R1
            SUBI R1, R1, #1
            JNZ LOOP
            STORE R2, #0x2000
            HALT
            "#,
        );
        assert_eq!(emu.read_word(0x2000).unwrap(), 55);
    }

    #[test]
    fn memory_roundtrip() {
        let emu = run_program(
            r#"
            LOADI R4, #0x12345678
            STORE R4, #0x2100
            LOADI R5, #0
            LOAD R5, #0x2100
            HALT
            "#,
        );
        assert_eq!(emu.registers[5], 0x12345678);
    }

    #[test]
    fn r0_hardwired_zero() {
        let emu = run_program(
            r#"
            LOADI R0, #12345
            ADDI R0, R0, #1
            HALT
            "#,
        );
        assert_eq!(emu.registers[0], 0);
    }
}

#[cfg(test)]
mod instruction_tests {
    use super::*;

    fn run_program(asm: &str) -> Custom32Emulator {
        let mut emu = Custom32Emulator::default();
        emu.load_assembly_text(asm).expect("parse failed");
        emu.run(20_000, false).expect("run failed");
        emu
    }

    #[test]
    fn loadi_works() {
        let emu = run_program(
            r#"
            LOADI R1, #123
            HALT
            "#,
        );
        assert_eq!(emu.registers[1], 123);
    }

    #[test]
    fn add_and_addi_work() {
        let emu = run_program(
            r#"
            LOADI R1, #10
            LOADI R2, #20
            ADD R3, R1, R2
            ADDI R4, R3, #5
            HALT
            "#,
        );
        assert_eq!(emu.registers[3], 30);
        assert_eq!(emu.registers[4], 35);
    }

    #[test]
    fn sub_and_subi_work() {
        let emu = run_program(
            r#"
            LOADI R1, #50
            LOADI R2, #8
            SUB R3, R1, R2
            SUBI R4, R3, #2
            HALT
            "#,
        );
        assert_eq!(emu.registers[3], 42);
        assert_eq!(emu.registers[4], 40);
    }

    #[test]
    fn and_or_xor_work() {
        let emu = run_program(
            r#"
            LOADI R1, #0xF0
            LOADI R2, #0xCC
            AND R3, R1, R2
            OR R4, R1, R2
            XOR R5, R1, R2
            HALT
            "#,
        );
        assert_eq!(emu.registers[3], 0xC0);
        assert_eq!(emu.registers[4], 0xFC);
        assert_eq!(emu.registers[5], 0x3C);
    }

    #[test]
    fn shl_and_shr_work() {
        let emu = run_program(
            r#"
            LOADI R1, #1
            SHL R2, R1, #5
            SHR R3, R2, #2
            HALT
            "#,
        );
        assert_eq!(emu.registers[2], 32);
        assert_eq!(emu.registers[3], 8);
    }

    #[test]
    fn load_and_store_work() {
        let emu = run_program(
            r#"
            LOADI R7, #0x11223344
            STORE R7, #0x300
            LOADI R8, #0
            LOAD R8, #0x300
            HALT
            "#,
        );
        assert_eq!(emu.registers[8], 0x11223344);
        assert_eq!(emu.read_word(0x300).unwrap(), 0x11223344);
    }

    #[test]
    fn jmp_works() {
        let emu = run_program(
            r#"
            JMP SKIP
            LOADI R1, #999
        SKIP:
            LOADI R1, #55
            HALT
            "#,
        );
        assert_eq!(emu.registers[1], 55);
    }

    #[test]
    fn cmp_and_jz_work() {
        let emu = run_program(
            r#"
            LOADI R1, #42
            LOADI R2, #42
            CMP R1, R2
            JZ EQUAL
            LOADI R3, #0
            JMP END
        EQUAL:
            LOADI R3, #1
        END:
            HALT
            "#,
        );
        assert_eq!(emu.registers[3], 1);
    }

    #[test]
    fn jnz_works() {
        let emu = run_program(
            r#"
            LOADI R1, #7
            LOADI R2, #8
            CMP R1, R2
            JNZ NEQ
            LOADI R3, #0
            JMP END
        NEQ:
            LOADI R3, #1
        END:
            HALT
            "#,
        );
        assert_eq!(emu.registers[3], 1);
    }

    #[test]
    fn jc_and_jnc_work() {
        let emu = run_program(
            r#"
            LOADI R1, #5
            LOADI R2, #3
            CMP R1, R2
            JC HAS_CARRY
            LOADI R3, #0
            JMP CHECK_JNC
        HAS_CARRY:
            LOADI R3, #1

        CHECK_JNC:
            CMP R2, R1
            JNC NO_CARRY
            LOADI R4, #0
            JMP END
        NO_CARRY:
            LOADI R4, #1
        END:
            HALT
            "#,
        );
        assert_eq!(emu.registers[3], 1);
        assert_eq!(emu.registers[4], 1);
    }

    #[test]
    fn jlt_jge_jle_work() {
        let emu = run_program(
            r#"
            LOADI R1, #1
            LOADI R2, #2
            CMP R1, R2
            JLT LESS
            LOADI R10, #0
            JMP CHECK_JGE
        LESS:
            LOADI R10, #1

        CHECK_JGE:
            CMP R2, R1
            JGE GE_TRUE
            LOADI R11, #0
            JMP CHECK_JLE
        GE_TRUE:
            LOADI R11, #1

        CHECK_JLE:
            CMP R1, R1
            JLE LE_TRUE
            LOADI R12, #0
            JMP END
        LE_TRUE:
            LOADI R12, #1
        END:
            HALT
            "#,
        );
        assert_eq!(emu.registers[10], 1);
        assert_eq!(emu.registers[11], 1);
        assert_eq!(emu.registers[12], 1);
    }

    #[test]
    fn directives_are_ignored() {
        let emu = run_program(
            r#"
            .org 0x8000
            .text
            LOADI R1, #77
            HALT
            "#,
        );
        assert_eq!(emu.registers[1], 77);
    }

    #[test]
    fn unaligned_memory_errors() {
        let mut emu = Custom32Emulator::default();
        emu.load_assembly_text(
            r#"
            LOADI R1, #1
            STORE R1, #0x101
            HALT
            "#,
        )
        .unwrap();

        let err = emu.run(100, false).unwrap_err();
        let msg = err.to_string();
        assert!(msg.contains("Unaligned STORE"));
    }
}

#[cfg(test)]
mod advanced_instruction_tests {
    use super::*;

    fn run_program(asm: &str) -> Custom32Emulator {
        let mut emu = Custom32Emulator::default();
        emu.load_assembly_text(asm).expect("parse failed");
        emu.run(50_000, false).expect("run failed");
        emu
    }

    #[test]
    fn add_sets_zero_flag_when_result_zero() {
        let emu = run_program(
            r#"
            LOADI R1, #0
            LOADI R2, #0
            ADD R3, R1, R2
            HALT
            "#,
        );
        assert_eq!(emu.registers[3], 0);
        assert!(emu.flags.zero);
    }

    #[test]
    fn subi_wraps_underflow_and_sets_negative() {
        let emu = run_program(
            r#"
            LOADI R1, #0
            SUBI R2, R1, #1
            HALT
            "#,
        );
        assert_eq!(emu.registers[2], 0xFFFF_FFFF);
        assert!(emu.flags.negative);
    }

    #[test]
    fn shl_masks_shift_amount_to_31() {
        let emu = run_program(
            r#"
            LOADI R1, #1
            SHL R2, R1, #33
            HALT
            "#,
        );
        assert_eq!(emu.registers[2], 2);
    }

    #[test]
    fn shr_masks_shift_amount_to_31() {
        let emu = run_program(
            r#"
            LOADI R1, #8
            SHR R2, R1, #34
            HALT
            "#,
        );
        assert_eq!(emu.registers[2], 2);
    }

    #[test]
    fn jmp_immediate_instruction_index_works() {
        let emu = run_program(
            r#"
            JMP #2
            LOADI R1, #999
            LOADI R1, #42
            HALT
            "#,
        );
        assert_eq!(emu.registers[1], 42);
    }

    #[test]
    fn load_store_with_register_based_addressing() {
        let emu = run_program(
            r#"
            LOADI R1, #0x4444
            LOADI R10, #0x340
            STORE R1, R10
            LOADI R2, #0
            LOAD R2, R10
            HALT
            "#,
        );
        assert_eq!(emu.registers[2], 0x4444);
    }

    #[test]
    fn duplicate_label_is_rejected() {
        let mut emu = Custom32Emulator::default();
        let err = emu
            .load_assembly_text(
                r#"
                A:
                LOADI R1, #1
                A:
                HALT
                "#,
            )
            .unwrap_err();
        assert!(err.to_string().contains("Duplicate label"));
    }

    #[test]
    fn unsupported_opcode_is_rejected() {
        let mut emu = Custom32Emulator::default();
        emu.load_assembly_text(
            r#"
            MUL R1, R2, R3
            HALT
            "#,
        )
        .unwrap();
        let err = emu.run(100, false).unwrap_err();
        assert!(err.to_string().contains("Unsupported opcode"));
    }

    #[test]
    fn wrong_argument_count_is_rejected() {
        let mut emu = Custom32Emulator::default();
        emu.load_assembly_text(
            r#"
            ADD R1, R2
            HALT
            "#,
        )
        .unwrap();
        let err = emu.run(100, false).unwrap_err();
        assert!(err.to_string().contains("Wrong arg count"));
    }

    #[test]
    fn table_driven_logic_cases() {
        let cases = [
            ("AND", 0xAAu32, 0xCCu32, 0x88u32),
            ("OR", 0xAAu32, 0xCCu32, 0xEEu32),
            ("XOR", 0xAAu32, 0xCCu32, 0x66u32),
        ];

        for (op, a, b, expected) in cases {
            let asm = format!(
                "\nLOADI R1, #{a}\nLOADI R2, #{b}\n{op} R3, R1, R2\nHALT\n"
            );
            let emu = run_program(&asm);
            assert_eq!(emu.registers[3], expected, "failed case for {op}");
        }
    }
}
