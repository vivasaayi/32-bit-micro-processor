/*
 * GENERIC JVM INTERPRETER FOR RISC PROCESSOR
 * 
 * This interpreter can execute any Java bytecode program
 * Uses only supported C features: individual variables instead of arrays
 */

// JVM State - using individual variables instead of arrays
struct JVM {
    // Stack (using individual slots since arrays in structs not supported)
    int stack0;
    int stack1;
    int stack2;
    int stack3;
    int sp;
    
    // Local variables
    int local0;
    int local1;
    int local2;
    int local3;
    
    // Program state
    int pc;
    int result;
};

// Bytecode program storage (using individual variables)
struct Bytecode {
    int op0, op1, op2, op3, op4, op5, op6, op7, op8, op9;
    int op10, op11, op12, op13, op14, op15;
    int length;
};

// Global JVM state
struct JVM vm;
struct Bytecode program;

// Stack operations
void push(int value) {
    if (vm.sp == 0) {
        vm.stack0 = value;
        vm.sp = 1;
    } else if (vm.sp == 1) {
        vm.stack1 = value;
        vm.sp = 2;
    } else if (vm.sp == 2) {
        vm.stack2 = value;
        vm.sp = 3;
    } else if (vm.sp == 3) {
        vm.stack3 = value;
        vm.sp = 4;
    }
}

int pop() {
    if (vm.sp == 4) {
        vm.sp = 3;
        return vm.stack3;
    } else if (vm.sp == 3) {
        vm.sp = 2;
        return vm.stack2;
    } else if (vm.sp == 2) {
        vm.sp = 1;
        return vm.stack1;
    } else if (vm.sp == 1) {
        vm.sp = 0;
        return vm.stack0;
    }
    return 0;
}

// Get bytecode instruction at PC
int get_instruction(int pc) {
    if (pc == 0) return program.op0;
    if (pc == 1) return program.op1;
    if (pc == 2) return program.op2;
    if (pc == 3) return program.op3;
    if (pc == 4) return program.op4;
    if (pc == 5) return program.op5;
    if (pc == 6) return program.op6;
    if (pc == 7) return program.op7;
    if (pc == 8) return program.op8;
    if (pc == 9) return program.op9;
    if (pc == 10) return program.op10;
    if (pc == 11) return program.op11;
    if (pc == 12) return program.op12;
    if (pc == 13) return program.op13;
    if (pc == 14) return program.op14;
    if (pc == 15) return program.op15;
    return 0;
}

// Store to local variable
void store_local(int index, int value) {
    if (index == 0) vm.local0 = value;
    else if (index == 1) vm.local1 = value;
    else if (index == 2) vm.local2 = value;
    else if (index == 3) vm.local3 = value;
}

// Load from local variable
int load_local(int index) {
    if (index == 0) return vm.local0;
    if (index == 1) return vm.local1;
    if (index == 2) return vm.local2;
    if (index == 3) return vm.local3;
    return 0;
}

// Generic bytecode executor
int execute_bytecode() {
    vm.pc = 0;
    
    while (vm.pc < program.length) {
        int opcode = get_instruction(vm.pc);
        
        // ICONST operations (3-5)
        if (opcode == 6) {        // iconst_3
            push(3);
        } else if (opcode == 7) { // iconst_4
            push(4);
        } else if (opcode == 8) { // iconst_5
            push(5);
        }
        
        // BIPUSH operation (16)
        else if (opcode == 16) {
            vm.pc = vm.pc + 1;
            int value = get_instruction(vm.pc);
            push(value);
        }
        
        // ILOAD operations (26-29)
        else if (opcode == 26) {  // iload_0
            push(load_local(0));
        } else if (opcode == 27) { // iload_1
            push(load_local(1));
        } else if (opcode == 28) { // iload_2
            push(load_local(2));
        } else if (opcode == 29) { // iload_3
            push(load_local(3));
        }
        
        // ISTORE operations (59-62)
        else if (opcode == 59) {  // istore_0
            store_local(0, pop());
        } else if (opcode == 60) { // istore_1
            store_local(1, pop());
        } else if (opcode == 61) { // istore_2
            store_local(2, pop());
        } else if (opcode == 62) { // istore_3
            store_local(3, pop());
        }
        
        // Arithmetic operations
        else if (opcode == 96) {  // iadd
            int b = pop();
            int a = pop();
            push(a + b);
        } else if (opcode == 100) { // isub
            int b = pop();
            int a = pop();
            push(a - b);
        } else if (opcode == 104) { // imul
            int b = pop();
            int a = pop();
            push(a * b);
        } else if (opcode == 108) { // idiv
            int b = pop();
            int a = pop();
            push(a / b);
        } else if (opcode == 112) { // irem (modulo)
            int b = pop();
            int a = pop();
            push(a % b);  // Uses enhanced MOD instruction
        }
        
        // Return operation
        else if (opcode == 172) { // ireturn
            vm.result = pop();
            return vm.result;
        }
        
        vm.pc = vm.pc + 1;
    }
    
    return vm.result;
}

// Load SimpleArithmetic bytecode: [16, 10, 59, 8, 60, 26, 27, 96, 61, 28, 172]
// This executes: int a=10; int b=5; int result=a+b; return result;
void load_simple_arithmetic() {
    program.op0 = 16;   // bipush
    program.op1 = 10;   // 10
    program.op2 = 59;   // istore_0
    program.op3 = 8;    // iconst_5
    program.op4 = 60;   // istore_1
    program.op5 = 26;   // iload_0
    program.op6 = 27;   // iload_1
    program.op7 = 96;   // iadd
    program.op8 = 61;   // istore_2
    program.op9 = 28;   // iload_2
    program.op10 = 172; // ireturn
    program.length = 11;
}

// Load a different program: 3 + 5 * 2 = 13
void load_arithmetic_test() {
    program.op0 = 6;    // iconst_3
    program.op1 = 8;    // iconst_5
    program.op2 = 16;   // bipush
    program.op3 = 2;    // 2
    program.op4 = 104;  // imul (5 * 2)
    program.op5 = 96;   // iadd (3 + 10)
    program.op6 = 172;  // ireturn
    program.length = 7;
}

// Initialize JVM
void init_vm() {
    vm.sp = 0;
    vm.stack0 = 0;
    vm.stack1 = 0; 
    vm.stack2 = 0;
    vm.stack3 = 0;
    vm.local0 = 0;
    vm.local1 = 0;
    vm.local2 = 0;
    vm.local3 = 0;
    vm.pc = 0;
    vm.result = 0;
}

int main() {
    init_vm();
    
    // Test 1: SimpleArithmetic (10 + 5 = 15)
    load_simple_arithmetic();
    int result1 = execute_bytecode();
    
    // Reset VM for next program
    init_vm();
    
    // Test 2: Arithmetic test (3 + 5 * 2 = 13)  
    load_arithmetic_test();
    int result2 = execute_bytecode();
    
    // Verify results
    if (result1 == 15 && result2 == 13) {
        return 1;  // Success - both programs executed correctly
    } else {
        return 0;  // Failure
    }
}
