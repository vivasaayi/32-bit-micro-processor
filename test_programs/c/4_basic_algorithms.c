/*
 * Basic Algorithm Demo
 * Simple algorithms without complex operators
 */

int main() {
    log_string("=== Basic Algorithms ===\n");
    
    // Simple sorting of 3 numbers
    log_string("Sorting 3 numbers\n");
    int a = 30;
    int b = 10;
    int c = 20;
    
    log_string("Initial: 30,10,20\n");
    
    // Bubble sort for 3 elements
    if (a > b) {
        int temp = a;
        a = b;
        b = temp;
        log_string("Swapped a,b\n");
    }
    
    if (b > c) {
        int temp = b;
        b = c;
        c = temp;
        log_string("Swapped b,c\n");
    }
    
    if (a > b) {
        int temp = a;
        a = b;
        b = temp;
        log_string("Swapped a,b again\n");
    }
    
    log_string("Sort completed\n");
    
    // Should be 10, 20, 30
    if (a == 10 && b == 20 && c == 30) {
        log_string("✓ Sort PASSED\n");
    } else {
        log_string("✗ Sort FAILED\n");
        return 0;
    }
    
    // Simple Fibonacci
    log_string("Fibonacci sequence\n");
    int f1 = 0;
    int f2 = 1;
    
    log_string("F0=0, F1=1\n");
    
    int f3 = f1 + f2; // 1
    log_string("F2 calculated\n");
    
    int f4 = f2 + f3; // 2
    log_string("F3 calculated\n");
    
    int f5 = f3 + f4; // 3
    log_string("F4 calculated\n");
    
    if (f5 == 3) {
        log_string("✓ Fibonacci PASSED\n");
    } else {
        log_string("✗ Fibonacci FAILED\n");
        return 0;
    }
    
    // Simple factorial
    log_string("Factorial 4!\n");
    int fact = 1;
    fact = fact * 1;
    fact = fact * 2;
    fact = fact * 3;
    fact = fact * 4;
    
    log_string("4! calculated\n");
    
    if (fact == 24) {
        log_string("✓ Factorial PASSED\n");
    } else {
        log_string("✗ Factorial FAILED\n");
        return 0;
    }
    
    // Sum calculation
    log_string("Sum 1+2+3+4+5\n");
    int sum = 0;
    sum = sum + 1;
    sum = sum + 2;
    sum = sum + 3;
    sum = sum + 4;
    sum = sum + 5;
    
    log_string("Sum calculated\n");
    
    if (sum == 15) {
        log_string("✓ Sum PASSED\n");
    } else {
        log_string("✗ Sum FAILED\n");
        return 0;
    }
    
    // Maximum of 4 numbers
    log_string("Finding maximum\n");
    int n1 = 45;
    int n2 = 23;
    int n3 = 67;
    int n4 = 34;
    
    log_string("Numbers: 45,23,67,34\n");
    
    int max = n1;
    if (n2 > max) {
        max = n2;
        log_string("New max: n2\n");
    }
    if (n3 > max) {
        max = n3;
        log_string("New max: n3\n");
    }
    if (n4 > max) {
        max = n4;
        log_string("New max: n4\n");
    }
    
    log_string("Max calculated\n");
    
    if (max == 67) {
        log_string("✓ Max PASSED\n");
    } else {
        log_string("✗ Max FAILED\n");
        return 0;
    }
    
    // All tests passed
    log_string("All tests completed!\n");
    log_string("=== Success! ===\n");
    
    return 1;
}
