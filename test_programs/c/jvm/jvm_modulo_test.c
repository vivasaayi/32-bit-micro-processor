// JVM test with modulo operation - demonstrates IREM bytecode
// Simulates Java: "17 % 5 + 3 = 5"

int main() {
    int stack = 0;
    int temp = 0;
    
    // Simulate Java bytecode: 17 % 5 + 3
    
    // ICONST_M1 (17) - using assignment since we don't have ICONST_17
    stack = 17;
    
    // ICONST_5
    temp = 5;
    
    // IREM (modulo operation) - uses our new MOD instruction!
    stack = stack % temp;  // 17 % 5 = 2
    
    // ICONST_3
    temp = 3;
    
    // IADD 
    stack = stack + temp;  // 2 + 3 = 5
    
    // Return the calculated value: should be 5
    return stack;
}
