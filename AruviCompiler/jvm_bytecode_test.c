int main() {
    int bytecode[] = {7, 6, 96, 172};
    
    int stack[10];
    int sp = 0;
    int pc = 0;
    int result = 0;
    
    while (pc < 4) {
        int opcode = bytecode[pc];
        pc = pc + 1;
        
        if (opcode == 7) {
            stack[sp] = 5;
            sp = sp + 1;
        }
        
        if (opcode == 6) {
            stack[sp] = 3;
            sp = sp + 1;
        }
        
        if (opcode == 96) {
            sp = sp - 1;
            int b = stack[sp];
            sp = sp - 1;
            int a = stack[sp];
            stack[sp] = a + b;
            sp = sp + 1;
        }
        
        if (opcode == 172) {
            sp = sp - 1;
            result = stack[sp];
            return result;
        }
    }
    
    return result;
}
