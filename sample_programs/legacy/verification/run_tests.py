import os
import subprocess
import glob
import sys

# Paths
ROOT_DIR = os.getcwd()
TOOLS_DIR = os.path.join(ROOT_DIR, "tools")
COMPILER_DIR = os.path.join(ROOT_DIR, "compiler")
ASSEMBLER = os.path.join(ROOT_DIR, "temp/assembler") # Use the temp one we verified
COMPILER = os.path.join(COMPILER_DIR, "ccompiler")
VERIF_DIR = os.path.join(ROOT_DIR, "verification")
ASM_DIR = os.path.join(VERIF_DIR, "asm")
C_DIR = os.path.join(VERIF_DIR, "c")
VVP_FILE = os.path.join(ROOT_DIR, "processor/testbench/microprocessor_system.vvp")

# Colors
GREEN = '\033[92m'
RED = '\033[91m'
RESET = '\033[0m'

def run_assembler(asm_file, hex_file):
    try:
        subprocess.check_output([ASSEMBLER, asm_file, hex_file], stderr=subprocess.STDOUT)
        return True, ""
    except subprocess.CalledProcessError as e:
        return False, e.output.decode()

def run_compiler(c_file, asm_file):
    try:
        # Compiler writes to output.s, we need to move it
        subprocess.check_output([COMPILER, c_file], stderr=subprocess.STDOUT)
        if os.path.exists("output.s"):
            os.rename("output.s", asm_file)
            return True, ""
        return False, "Output file not generated"
    except subprocess.CalledProcessError as e:
        return False, e.output.decode()

def run_simulation(hex_file):
    try:
        # Run vvp with argument
        # +hexfile=<path>
        # We need to capture stdout
        cmd = ["vvp", VVP_FILE, f"+hexfile={hex_file}"]
        result = subprocess.run(cmd, capture_output=True, text=True)
        return result.stdout
    except Exception as e:
        return str(e)

def verify_test(test_name, output):
    if "PASSED" in output or "SORTING TEST PASSED" in output:
        return True
    return False

def main():
    print(f"Starting verification in {ROOT_DIR}...")
    
    # Ensure tools exist
    if not os.path.exists(ASSEMBLER):
        print(f"{RED}Assembler not found at {ASSEMBLER}{RESET}")
        return
    if not os.path.exists(VVP_FILE):
        print(f"{RED}Simulation file not found at {VVP_FILE}. Run 'make' first.{RESET}")
        subprocess.run(["make"], cwd=ROOT_DIR, stdout=subprocess.DEVNULL)

    tests_passed = 0
    tests_failed = 0
    
    # 1. Run Assembly Tests
    print("\n=== Running Assembly Instruction Tests ===")
    asm_files = glob.glob(os.path.join(ASM_DIR, "*.asm"))
    for asm_file in asm_files:
        basename = os.path.basename(asm_file)
        hex_file = asm_file.replace(".asm", ".hex")
        
        print(f"Testing {basename}...", end="", flush=True)
        
        success, msg = run_assembler(asm_file, hex_file)
        if not success:
            print(f" {RED}ASSEMBLY FAILED{RESET}")
            print(msg)
            tests_failed += 1
            continue
            
        output = run_simulation(hex_file)
        if verify_test(basename, output):
            print(f" {GREEN}PASSED{RESET}")
            tests_passed += 1
        else:
            print(f" {RED}FAILED{RESET}")
            # print(output) # Optional: print output on fail
            tests_failed += 1

    # 2. Run C Integration Tests
    print("\n=== Running C Integration Tests ===")
    c_files = glob.glob(os.path.join(C_DIR, "*.c"))
    for c_file in c_files:
        basename = os.path.basename(c_file)
        asm_file = c_file.replace(".c", ".asm")
        hex_file = c_file.replace(".c", ".hex")
        
        print(f"Testing {basename}...", end="", flush=True)
        
        success, msg = run_compiler(c_file, asm_file)
        if not success:
            print(f" {RED}COMPILATION FAILED{RESET}")
            print(msg)
            tests_failed += 1
            continue
            
        success, msg = run_assembler(asm_file, hex_file)
        if not success:
            print(f" {RED}ASSEMBLY FAILED{RESET}")
            print(msg)
            tests_failed += 1
            continue
            
        output = run_simulation(hex_file)
        if verify_test(basename, output):
            print(f" {GREEN}PASSED{RESET}")
            tests_passed += 1
        else:
            print(f" {RED}FAILED{RESET}")
            # print(output)
            tests_failed += 1

    print(f"\nSummary: {tests_passed} Passed, {tests_failed} Failed")

if __name__ == "__main__":
    main()
