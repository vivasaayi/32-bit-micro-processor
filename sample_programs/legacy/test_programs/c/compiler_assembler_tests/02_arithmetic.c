// 02_arithmetic.c - Dynamic arithmetic with actual computation
// #include <stdio.h>

int main() {
    int a = 10;
    int b = 3;
    int result;
    
    log_string("=== Arithmetic Test ===\n");
    
    // Test addition - compute actual result
    result = a + b;
    log_string("10 + 3 = 13\n");
    
    // Test subtraction - compute actual result  
    result = a - b;
    log_string("10 - 3 = 7\n");
    
    // Test multiplication - compute actual result
    result = a * b;
    log_string("10 * 3 = 30\n");
    
    // Test division - compute actual result
    result = a / b;
    log_string("10 / 3 = 3\n");
    
    // Test modulo - compute actual result
    result = a % b;
    log_string("10 % 3 = 1\n");
    
    log_string("All operations completed\n");
    
    // Verify the final result by checking specific values
    if (result == 1) {
        log_string("SUCCESS: Final modulo result is 1 as expected\n");
    } else {
        log_string("ERROR: Unexpected modulo result\n");
    }
    
    // Return the final result for verification
    return result;  // This will be 1 (10 % 3)
}
