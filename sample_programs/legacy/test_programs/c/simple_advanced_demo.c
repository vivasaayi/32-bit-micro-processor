/*
 * Simplified Advanced DSA Demo
 * Demonstrates complex algorithms within compiler limitations
 */

int main() {
    log_string("=== Advanced DSA Demo ===\n");
    
    // Array initialization
    log_string("Initializing array[4]\n");
    int arr[4];
    arr[0] = 64;
    arr[1] = 34; 
    arr[2] = 25;
    arr[3] = 12;
    
    log_string("Array: [64,34,25,12]\n");
    
    // Simple Bubble Sort (fixed iterations)
    log_string("Starting Bubble Sort...\n");
    int n = 4;
    
    // Pass 1
    log_string("Pass 1 starting\n");
    for (int j = 0; j < 3; j++) {
        if (arr[j] > arr[j + 1]) {
            log_string("Swapping elements\n");
            int temp = arr[j];
            arr[j] = arr[j + 1];
            arr[j + 1] = temp;
        }
    }
    
    // Pass 2
    log_string("Pass 2 starting\n");
    for (int j = 0; j < 2; j++) {
        if (arr[j] > arr[j + 1]) {
            log_string("Swapping elements\n");
            int temp = arr[j];
            arr[j] = arr[j + 1];
            arr[j + 1] = temp;
        }
    }
    
    // Pass 3
    log_string("Pass 3 starting\n");
    for (int j = 0; j < 1; j++) {
        if (arr[j] > arr[j + 1]) {
            log_string("Swapping elements\n");
            int temp = arr[j];
            arr[j] = arr[j + 1];
            arr[j + 1] = temp;
        }
    }
    
    log_string("Bubble sort completed\n");
    
    // Verify sorting (12, 25, 34, 64)
    log_string("Verifying sort...\n");
    if (arr[0] == 12 && arr[1] == 25 && arr[2] == 34 && arr[3] == 64) {
        log_string("✓ Array is sorted!\n");
    } else {
        log_string("✗ Sort failed!\n");
        return 0;
    }
    
    // Linear Search Demo
    log_string("Linear Search Demo\n");
    int target = 25;
    int found = -1;
    
    log_string("Searching for 25...\n");
    
    for (int i = 0; i < n; i++) {
        log_string("Checking element\n");
        if (arr[i] == target) {
            found = i;
            log_string("Target found!\n");
            break;
        }
    }
    
    if (found >= 0) {
        log_string("✓ Search success\n");
    } else {
        log_string("✗ Search failed\n");
        return 0;
    }
    
    // Fibonacci Sequence (first 6 numbers)
    log_string("Fibonacci sequence:\n");
    int fib1 = 0;
    int fib2 = 1;
    
    log_string("F(0) = 0\n");
    log_string("F(1) = 1\n");
    
    // Calculate F(2) through F(5)
    int next = fib1 + fib2; // F(2) = 1
    log_string("F(2) calculated\n");
    fib1 = fib2;
    fib2 = next;
    
    next = fib1 + fib2; // F(3) = 2
    log_string("F(3) calculated\n");
    fib1 = fib2;
    fib2 = next;
    
    next = fib1 + fib2; // F(4) = 3
    log_string("F(4) calculated\n");
    fib1 = fib2;
    fib2 = next;
    
    next = fib1 + fib2; // F(5) = 5
    log_string("F(5) calculated\n");
    log_string("Fibonacci complete\n");
    
    // Factorial calculation (5!)
    log_string("Calculating 5!\n");
    int factorial = 1;
    factorial = factorial * 1; // 1!
    factorial = factorial * 2; // 2!
    factorial = factorial * 3; // 3!
    factorial = factorial * 4; // 4!
    factorial = factorial * 5; // 5!
    
    log_string("Factorial steps done\n");
    
    if (factorial == 120) {
        log_string("✓ Factorial correct\n");
    } else {
        log_string("✗ Factorial wrong\n");
        return 0;
    }
    
    // Sum of array elements
    log_string("Calculating array sum\n");
    int sum = 0;
    sum = sum + arr[0];
    sum = sum + arr[1];
    sum = sum + arr[2];
    sum = sum + arr[3];
    
    // Expected sum: 12 + 25 + 34 + 64 = 135
    if (sum == 135) {
        log_string("✓ Sum correct (135)\n");
    } else {
        log_string("✗ Sum incorrect\n");
        return 0;
    }
    
    // Find min and max
    log_string("Finding min and max\n");
    int min = arr[0];
    int max = arr[0];
    
    if (arr[1] < min) min = arr[1];
    if (arr[2] < min) min = arr[2];
    if (arr[3] < min) min = arr[3];
    
    if (arr[1] > max) max = arr[1];
    if (arr[2] > max) max = arr[2];
    if (arr[3] > max) max = arr[3];
    
    if (min == 12 && max == 64) {
        log_string("✓ Min/Max correct\n");
    } else {
        log_string("✗ Min/Max wrong\n");
        return 0;
    }
    
    // Final verification
    log_string("All tests passed!\n");
    log_string("=== Demo Complete ===\n");
    
    return 1; // Success
}
