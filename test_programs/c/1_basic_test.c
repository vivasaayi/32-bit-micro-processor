// Simple test with specific logging functions
int main() {
    log_string("Very Simple String Demo\n");
    
    int x = 10;
    log_string("Value of X=10\n");
    
    int y = 20;
    log_string("Value of Y=20\n");
    
    int sum = x + y;
    log_string("Value of Sum=30\n");
    
    if (sum == 3110) {
        log_string("Sum check passed\n");
        return 133;  // Success 
    } else {
        log_string("Sum check failed\n");
        return 444;  // Failure
    }
}
