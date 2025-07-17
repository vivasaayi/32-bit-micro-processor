#!/usr/bin/env python3

def analyze_assembly():
    """Analyze the x_4_mul_by_add.asm assembly process step by step"""
    
    print("=== ASSEMBLY ANALYSIS: x_4_mul_by_add.asm ===")
    print()
    
    # Simulate the assembler's first pass
    lines = [
        "main:",
        "    LOADI R1, #7",
        "    LOADI R2, #6", 
        "    LOADI R3, #0",
        "mul_loop:",
        "    CMP R2, R0",
        "    JZ end_mul",
        "    ADD R3, R3, R1",
        "    SUBI R2, R2, #1",
        "    JMP mul_loop",
        "end_mul:",
        "    STORE R3, 0x7000",
        "    HALT"
    ]
    
    current_address = 0x8000  # Base address
    labels = {}
    instructions = []
    
    print("FIRST PASS - Label collection:")
    print("-" * 40)
    
    for line_num, line in enumerate(lines):
        line = line.strip()
        if ':' in line:
            # It's a label
            label_name = line.replace(':', '').strip()
            labels[label_name] = current_address
            print(f"Label '{label_name}' -> 0x{current_address:08X}")
            
            # Check if there's an instruction after the label
            if line.count(' ') > 0:
                # There's an instruction on the same line
                instruction = line.split(':', 1)[1].strip()
                if instruction:
                    instructions.append((current_address, instruction, line_num))
                    current_address += 4
        else:
            # It's a regular instruction
            if line and not line.startswith(';'):
                instructions.append((current_address, line, line_num))
                current_address += 4
    
    print()
    print("SECOND PASS - Jump offset calculation:")
    print("-" * 40)
    
    for addr, instruction, line_num in instructions:
        if instruction.strip().startswith('JMP'):
            parts = instruction.split()
            if len(parts) >= 2:
                target_label = parts[1]
                if target_label in labels:
                    target_addr = labels[target_label]
                    
                    # This is the key calculation from assembler.c line 777:
                    # immediate = (label_addr - (current_address + 4)) / 4;
                    offset_bytes = target_addr - (addr + 4)
                    offset_words = offset_bytes // 4
                    
                    print(f"JMP at 0x{addr:08X} -> {target_label} (0x{target_addr:08X})")
                    print(f"  Calculation: (0x{target_addr:08X} - (0x{addr:08X} + 4)) / 4")
                    print(f"  = (0x{target_addr:08X} - 0x{addr+4:08X}) / 4")
                    print(f"  = {offset_bytes} / 4 = {offset_words}")
                    print(f"  Encoded offset: 0x{offset_words & 0xFFF:03X}")
                    
                    # Check what we actually got in the hex file
                    print(f"  Expected in hex: 8000{offset_words & 0xFFF:04X}")
                    print()
    
    print("ACTUAL HEX FILE ANALYSIS:")
    print("-" * 40)
    
    # Read actual hex file
    hex_instructions = []
    try:
        with open("test_programs/assembly/x_4_mul_by_add.hex", "r") as f:
            for line in f:
                line = line.strip()
                if line:
                    hex_instructions.append(line)
    except FileNotFoundError:
        print("Hex file not found!")
        return
    
    base_addr = 0x8000
    for i, hex_val in enumerate(hex_instructions):
        addr = base_addr + (i * 4)
        
        if hex_val.startswith("81"):  # JMP instruction with relative addressing
            # Extract the 12-bit offset from bits [11:0]
            offset_bits = int(hex_val[5:], 16)  # Last 3 hex digits = 12 bits  
            if offset_bits > 2047:  # Check if it's negative (12-bit signed, range -2048 to +2047)
                offset = offset_bits - 4096
            else:
                offset = offset_bits
            print(f"0x{addr:08X}: {hex_val} (JMP with relative offset {offset}) [bits: 0x{offset_bits:03X}]")
            target = addr + 4 + (offset * 4)
            print(f"  Target address: 0x{addr:08X} + 4 + ({offset} * 4) = 0x{target:08X}")
        elif hex_val.startswith("80"):  # JMP instruction with absolute addressing
            # This was the old format
            offset = int(hex_val[4:], 16)
            if offset > 2048:  # Check if it's negative (12-bit signed)
                offset = offset - 4096
            print(f"0x{addr:08X}: {hex_val} (JMP with absolute offset {offset})")
            target = addr + 4 + (offset * 4)
            print(f"  Target address: 0x{addr:08X} + 4 + ({offset} * 4) = 0x{target:08X}")
        else:
            print(f"0x{addr:08X}: {hex_val}")

if __name__ == "__main__":
    analyze_assembly()
