// Native String Manipulation Demo
// Demonstrates the comprehensive logging capabilities

int main() {
    log_string("Starting Algorithm Demo\n");
    
    // Bubble sort algorithm with logging
    log_string("Initializing array\n");
    int a = 64;
    int b = 34; 
    int c = 12;
    
    log_string("Initial: 64, 34, 12\n");
    
    // First comparison
    if (a > b) {
        log_string("Swapping a and b\n");
        int temp = a;
        a = b;
        b = temp;
    }
    
    log_string("After pass 1\n");
    
    // Second comparison  
    if (b > c) {
        log_string("Swapping b and c\n");
        int temp = b;
        b = c;
        c = temp;
    }
    
    log_string("After pass 2\n");
    
    // Third comparison
    if (a > b) {
        log_string("Swapping a and b again\n");
        int temp = a;
        a = b;
        b = temp;
    }
    
    log_string("Final sorted order\n");
    log_string("Sort complete!\n");
    
    // Verification
    if (a <= b && b <= c) {
        log_string("✓ Sort verification PASSED\n");
        return 1;
    } else {
        log_string("✗ Sort verification FAILED\n");
        return 0;
    }
}
