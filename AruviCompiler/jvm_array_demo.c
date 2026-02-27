int main() {
    int opcodes[] = {3, 4, 5, 96, 172};
    int locals[5];
    int stack[20];
    
    locals[0] = 10;
    locals[1] = 20;
    locals[2] = 30;
    
    stack[0] = opcodes[0];
    stack[1] = opcodes[1] + locals[0];
    stack[2] = stack[0] + stack[1];
    
    return stack[2];
}
