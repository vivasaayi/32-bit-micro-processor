// Simple JVM test - returns the calculated value directly

int main() {
    int stack = 0;
    int temp = 0;
    
    // Simulate: ICONST_5 (push 5)
    stack = 5;
    
    // Simulate: ICONST_3 (push 3) 
    temp = 3;
    
    // Simulate: ICONST_2 (push 2)
    // Now we have 5, 3, 2 conceptually
    
    // Simulate: IMUL (3 * 2 = 6)
    temp = temp * 2;  // temp = 6
    
    // Simulate: IADD (5 + 6 = 11)
    stack = stack + temp;  // stack = 11
    
    // Return the calculated value directly
    return stack;
}
