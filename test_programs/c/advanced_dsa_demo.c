/*
 * Advanced Data Structures and Algorithms Demo
 * Demonstrates complex C programming features with string logging
 */

int main() {
    log_string("=== Advanced DSA Demo ===\n");
    
    // Array initialization and display
    log_string("Initializing array[5]\n");
    int arr[5];
    arr[0] = 64;
    arr[1] = 34; 
    arr[2] = 25;
    arr[3] = 12;
    arr[4] = 22;
    
    log_string("Array: [64,34,25,12,22]\n");
    
    // Bubble Sort Algorithm
    log_string("Starting Bubble Sort...\n");
    int n = 5;
    int swaps = 0;
    
    // Outer loop
    for (int i = 0; i < n - 1; i++) {
        log_string("Pass ");
        log_string("starting\n");
        
        int swapped = 0;
        
        // Inner loop
        for (int j = 0; j < n - i - 1; j++) {
            if (arr[j] > arr[j + 1]) {
                // Swap elements
                log_string("Swapping elements\n");
                int temp = arr[j];
                arr[j] = arr[j + 1];
                arr[j + 1] = temp;
                swaps++;
                swapped = 1;
            }
        }
        
        if (!swapped) {
            log_string("Early termination\n");
            break;
        }
    }
    
    log_string("Bubble sort completed\n");
    
    // Verify sorting
    log_string("Verifying sort...\n");
    int is_sorted = 1;
    for (int i = 0; i < n - 1; i++) {
        if (arr[i] > arr[i + 1]) {
            is_sorted = 0;
            break;
        }
    }
    
    if (is_sorted) {
        log_string("✓ Array is sorted!\n");
    } else {
        log_string("✗ Sort failed!\n");
        return 0;
    }
    
    // Binary Search Demo
    log_string("Binary Search Demo\n");
    int target = 25;
    int left = 0;
    int right = n - 1;
    int found = -1;
    
    log_string("Searching for 25...\n");
    
    while (left <= right) {
        int mid = (left + right) / 2;
        log_string("Checking middle\n");
        
        if (arr[mid] == target) {
            found = mid;
            log_string("Target found!\n");
            break;
        } else if (arr[mid] < target) {
            log_string("Search right half\n");
            left = mid + 1;
        } else {
            log_string("Search left half\n");
            right = mid - 1;
        }
    }
    
    if (found != -1) {
        log_string("✓ Binary search success\n");
    } else {
        log_string("✗ Binary search failed\n");
        return 0;
    }
    
    // Fibonacci Sequence
    log_string("Fibonacci sequence:\n");
    int fib1 = 0;
    int fib2 = 1;
    
    log_string("F(0) = 0\n");
    log_string("F(1) = 1\n");
    
    for (int i = 2; i < 8; i++) {
        int next = fib1 + fib2;
        fib1 = fib2;
        fib2 = next;
        log_string("Next Fibonacci\n");
    }
    
    log_string("Fibonacci complete\n");
    
    // Factorial calculation
    log_string("Calculating 5!\n");
    int factorial = 1;
    for (int i = 1; i <= 5; i++) {
        factorial = factorial * i;
        log_string("Factorial step\n");
    }
    
    if (factorial == 120) {
        log_string("✓ Factorial correct\n");
    } else {
        log_string("✗ Factorial wrong\n");
        return 0;
    }
    
    // Prime number check
    log_string("Prime number check\n");
    int num = 17;
    int is_prime = 1;
    
    if (num <= 1) {
        is_prime = 0;
    } else {
        for (int i = 2; i * i <= num; i++) {
            if (num % i == 0) {
                is_prime = 0;
                break;
            }
        }
    }
    
    if (is_prime) {
        log_string("✓ 17 is prime\n");
    } else {
        log_string("✗ 17 not prime\n");
        return 0;
    }
    
    // Final verification
    log_string("All tests passed!\n");
    log_string("=== Demo Complete ===\n");
    
    return 1; // Success
}
