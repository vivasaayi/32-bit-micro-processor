import unittest

from emulator import Custom32Emulator


class EmulatorTests(unittest.TestCase):
    def run_program(self, asm: str) -> Custom32Emulator:
        emu = Custom32Emulator()
        emu.load_assembly_text(asm)
        emu.run(max_steps=10_000)
        return emu

    def test_sum_loop(self) -> None:
        emu = self.run_program(
            """
            LOADI R1, #10
            LOADI R2, #0
        LOOP:
            ADD R2, R2, R1
            SUBI R1, R1, #1
            JNZ LOOP
            STORE R2, #0x2000
            HALT
            """
        )
        self.assertEqual(emu._read_word(0x2000), 55)

    def test_memory_roundtrip(self) -> None:
        emu = self.run_program(
            """
            LOADI R4, #0x12345678
            STORE R4, #0x2100
            LOADI R5, #0
            LOAD R5, #0x2100
            HALT
            """
        )
        self.assertEqual(emu.registers[5], 0x12345678)

    def test_r0_is_hardwired_zero(self) -> None:
        emu = self.run_program(
            """
            LOADI R0, #12345
            ADDI R0, R0, #1
            HALT
            """
        )
        self.assertEqual(emu.registers[0], 0)


if __name__ == "__main__":
    unittest.main()
