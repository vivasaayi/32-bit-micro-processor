/*
 * Algorithm Demo Without Arrays
 * Demonstrates algorithms using simple variables
 */

int main() {
    log_string("=== Algorithm Demo ===\n");
    
    // Variable-based sorting demo
    log_string("Sorting 4 numbers\n");
    int a = 64;
    int b = 34; 
    int c = 25;
    int d = 12;
    
    log_string("Initial: 64,34,25,12\n");
    
    // Sorting network for 4 elements
    log_string("Sorting pass 1\n");
    if (a > b) {
        int temp = a;
        a = b;
        b = temp;
        log_string("Swapped a,b\n");
    }
    
    if (c > d) {
        int temp = c;
        c = d;
        d = temp;
        log_string("Swapped c,d\n");
    }
    
    log_string("Sorting pass 2\n");
    if (a > c) {
        int temp = a;
        a = c;
        c = temp;
        log_string("Swapped a,c\n");
    }
    
    if (b > d) {
        int temp = b;
        b = d;
        d = temp;
        log_string("Swapped b,d\n");
    }
    
    log_string("Sorting pass 3\n");
    if (b > c) {
        int temp = b;
        b = c;
        c = temp;
        log_string("Swapped b,c\n");
    }
    
    log_string("Sort completed\n");
    
    // Verify sorting (should be 12, 25, 34, 64)
    if (a <= b && b <= c && c <= d) {
        log_string("✓ Sort verification PASSED\n");
    } else {
        log_string("✗ Sort verification FAILED\n");
        return 0;
    }
    
    // Fibonacci calculation
    log_string("Fibonacci calculation\n");
    int fib0 = 0;
    int fib1 = 1;
    
    log_string("F(0)=0, F(1)=1\n");
    
    int fib2 = fib0 + fib1; // F(2) = 1
    log_string("F(2) calculated\n");
    
    int fib3 = fib1 + fib2; // F(3) = 2
    log_string("F(3) calculated\n");
    
    int fib4 = fib2 + fib3; // F(4) = 3
    log_string("F(4) calculated\n");
    
    int fib5 = fib3 + fib4; // F(5) = 5
    log_string("F(5) calculated\n");
    
    if (fib5 == 5) {
        log_string("✓ Fibonacci correct\n");
    } else {
        log_string("✗ Fibonacci wrong\n");
        return 0;
    }
    
    // Factorial calculation
    log_string("Factorial calculation\n");
    int factorial = 1;
    factorial = factorial * 1;
    factorial = factorial * 2;
    factorial = factorial * 3;
    factorial = factorial * 4;
    factorial = factorial * 5;
    
    log_string("5! calculated\n");
    
    if (factorial == 120) {
        log_string("✓ Factorial correct\n");
    } else {
        log_string("✗ Factorial wrong\n");
        return 0;
    }
    
    // GCD calculation (Euclidean algorithm)
    log_string("GCD calculation\n");
    int x = 48;
    int y = 18;
    
    log_string("GCD(48, 18)\n");
    
    // Simple GCD implementation
    while (y != 0) {
        log_string("GCD iteration\n");
        int temp = y;
        y = x % y;
        x = temp;
    }
    
    log_string("GCD completed\n");
    
    if (x == 6) {
        log_string("✓ GCD correct (6)\n");
    } else {
        log_string("✗ GCD wrong\n");
        return 0;
    }
    
    // Power calculation (2^5)
    log_string("Power calculation\n");
    int base = 2;
    int power = 1;
    
    power = power * base; // 2^1
    power = power * base; // 2^2
    power = power * base; // 2^3
    power = power * base; // 2^4
    power = power * base; // 2^5
    
    log_string("2^5 calculated\n");
    
    if (power == 32) {
        log_string("✓ Power correct (32)\n");
    } else {
        log_string("✗ Power wrong\n");
        return 0;
    }
    
    // Sum of first 10 natural numbers
    log_string("Sum calculation\n");
    int sum = 0;
    sum = sum + 1;
    sum = sum + 2;
    sum = sum + 3;
    sum = sum + 4;
    sum = sum + 5;
    sum = sum + 6;
    sum = sum + 7;
    sum = sum + 8;
    sum = sum + 9;
    sum = sum + 10;
    
    log_string("Sum 1-10 calculated\n");
    
    if (sum == 55) {
        log_string("✓ Sum correct (55)\n");
    } else {
        log_string("✗ Sum wrong\n");
        return 0;
    }
    
    // Final result
    log_string("All algorithms passed!\n");
    log_string("=== Demo Complete ===\n");
    
    return 1; // Success
}
