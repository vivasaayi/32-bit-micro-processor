#!/bin/bash
# Comprehensive test runner for HDL Processor test programs

set -e  # Exit on any error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMP_DIR="$SCRIPT_DIR/temp"
C_PROGRAMS_DIR="$SCRIPT_DIR/test_programs/c"
ASM_PROGRAMS_DIR="$SCRIPT_DIR/test_programs/assembly"
C_COMPILER="$TEMP_DIR/c_compiler"
ASSEMBLER="$TEMP_DIR/assembler"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to test C programs
test_c_programs() {
    print_status $BLUE "🔍 Testing C Programs"
    print_status $BLUE "===================="
    
    local passed=0
    local failed=0
    local total=0
    
    if [ ! -d "$C_PROGRAMS_DIR" ]; then
        print_status $RED "❌ C programs directory not found: $C_PROGRAMS_DIR"
        return 1
    fi
    
    for c_file in "$C_PROGRAMS_DIR"/*.c; do
        if [ ! -f "$c_file" ]; then
            print_status $YELLOW "⚠️  No C files found in $C_PROGRAMS_DIR"
            break
        fi
        
        local basename=$(basename "$c_file" .c)
        local asm_file="$TEMP_DIR/${basename}.asm"
        local hex_file="$TEMP_DIR/${basename}.hex"
        
        echo ""
        print_status $BLUE "Testing: $basename"
        
        total=$((total + 1))
        
        # Step 1: Compile C to assembly
        if "$C_COMPILER" "$c_file" 2>/dev/null; then
            # Move generated assembly to temp
            if [ -f "$C_PROGRAMS_DIR/${basename}.asm" ]; then
                mv "$C_PROGRAMS_DIR/${basename}.asm" "$asm_file"
            fi
            print_status $GREEN "  ✅ C compilation successful"
        else
            print_status $RED "  ❌ C compilation failed"
            failed=$((failed + 1))
            continue
        fi
        
        # Step 2: Assemble to hex
        if "$ASSEMBLER" "$asm_file" "$hex_file" 2>/dev/null 1>/dev/null; then
            print_status $GREEN "  ✅ Assembly successful"
        else
            print_status $RED "  ❌ Assembly failed"
            failed=$((failed + 1))
            continue
        fi
        
        # Step 3: Check output files
        if [ -f "$hex_file" ] && [ -s "$hex_file" ]; then
            local hex_lines=$(wc -l < "$hex_file")
            print_status $GREEN "  ✅ Generated $hex_lines lines of hex code"
            passed=$((passed + 1))
        else
            print_status $RED "  ❌ No valid hex output generated"
            failed=$((failed + 1))
        fi
    done
    
    echo ""
    print_status $BLUE "C Programs Summary:"
    print_status $GREEN "  Passed: $passed"
    print_status $RED "  Failed: $failed"
    print_status $BLUE "  Total:  $total"
    
    return $failed
}

# Function to test assembly programs
test_assembly_programs() {
    print_status $BLUE "🔍 Testing Assembly Programs"
    print_status $BLUE "=========================="
    
    local passed=0
    local failed=0
    local total=0
    
    if [ ! -d "$ASM_PROGRAMS_DIR" ]; then
        print_status $RED "❌ Assembly programs directory not found: $ASM_PROGRAMS_DIR"
        return 1
    fi
    
    for asm_file in "$ASM_PROGRAMS_DIR"/*.asm; do
        if [ ! -f "$asm_file" ]; then
            print_status $YELLOW "⚠️  No assembly files found in $ASM_PROGRAMS_DIR"
            break
        fi
        
        local basename=$(basename "$asm_file" .asm)
        local hex_file="$TEMP_DIR/${basename}.hex"
        
        echo ""
        print_status $BLUE "Testing: $basename"
        
        total=$((total + 1))
        
        # Assemble to hex
        if "$ASSEMBLER" "$asm_file" "$hex_file" 2>/dev/null 1>/dev/null; then
            print_status $GREEN "  ✅ Assembly successful"
            
            if [ -f "$hex_file" ] && [ -s "$hex_file" ]; then
                local hex_lines=$(wc -l < "$hex_file")
                print_status $GREEN "  ✅ Generated $hex_lines lines of hex code"
                passed=$((passed + 1))
            else
                print_status $RED "  ❌ No valid hex output generated"
                failed=$((failed + 1))
            fi
        else
            print_status $RED "  ❌ Assembly failed"
            failed=$((failed + 1))
        fi
    done
    
    echo ""
    print_status $BLUE "Assembly Programs Summary:"
    print_status $GREEN "  Passed: $passed"
    print_status $RED "  Failed: $failed"
    print_status $BLUE "  Total:  $total"
    
    return $failed
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  c, --c-programs     Test only C programs"
    echo "  a, --assembly       Test only assembly programs"
    echo "  -h, --help          Show this help message"
    echo ""
    echo "If no options are provided, both C and assembly programs will be tested."
}

# Main function
main() {
    print_status $BLUE "🚀 HDL Processor Test Runner"
    print_status $BLUE "============================"
    
    # Ensure tools are built
    echo ""
    print_status $BLUE "Checking tools..."
    
    if [ ! -f "$C_COMPILER" ] || [ ! -f "$ASSEMBLER" ]; then
        print_status $YELLOW "⚠️  Tools not found, building them..."
        cd "$SCRIPT_DIR/tools"
        make all
        cd "$SCRIPT_DIR"
    fi
    
    print_status $GREEN "✅ Tools ready"
    print_status $BLUE "  C Compiler: $C_COMPILER"
    print_status $BLUE "  Assembler:  $ASSEMBLER"
    
    # Create temp directory if it doesn't exist
    mkdir -p "$TEMP_DIR"
    
    local test_c=false
    local test_asm=false
    local total_failures=0
    
    # Parse command line arguments
    if [ $# -eq 0 ]; then
        test_c=true
        test_asm=true
    else
        while [[ $# -gt 0 ]]; do
            case $1 in
                c|--c-programs)
                    test_c=true
                    shift
                    ;;
                a|--assembly)
                    test_asm=true
                    shift
                    ;;
                -h|--help)
                    show_usage
                    exit 0
                    ;;
                *)
                    print_status $RED "❌ Unknown option: $1"
                    show_usage
                    exit 1
                    ;;
            esac
        done
    fi
    
    echo ""
    
    # Run tests
    if [ "$test_c" = true ]; then
        test_c_programs
        total_failures=$((total_failures + $?))
        echo ""
    fi
    
    if [ "$test_asm" = true ]; then
        test_assembly_programs
        total_failures=$((total_failures + $?))
        echo ""
    fi
    
    # Final summary
    print_status $BLUE "🏁 Final Results"
    print_status $BLUE "==============="
    
    if [ $total_failures -eq 0 ]; then
        print_status $GREEN "🎉 All tests passed!"
        exit 0
    else
        print_status $RED "❌ $total_failures test(s) failed"
        exit 1
    fi
}

# Run main function with all arguments
main "$@"
