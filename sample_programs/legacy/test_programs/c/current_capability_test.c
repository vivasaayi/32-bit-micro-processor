// Current system capability test (no arrays, pointers, structs)
int factorial(int n) {
    if (n <= 1) {
        return 1;
    }
    return n * factorial(n - 1);
}

int main() {
    // Test basic arithmetic
    int a = 10;
    int b = 20;
    int sum = a + b;
    int product = a * b;
    
    // Test function call
    int fact5 = factorial(5);
    
    // Test conditional logic
    if (sum == 30 && product == 200 && fact5 == 120) {
        return 1; // PASS
    } else {
        return 0; // FAIL
    }
}
