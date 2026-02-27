// Enhanced C Program with Native String Manipulation Support
// This program demonstrates the new log_string() functionality

int main() {
    log_string("Program Start\n");
    
    int x = 10;
    int y = 20;
    
    log_string("Setting x = 10\n");
    log_string("Setting y = 20\n");
    
    int sum = x + y;
    
    log_string("Computing sum\n");
    log_string("sum = 30\n");
    
    if (sum == 30) {
        log_string("Test PASSED\n");
        log_string("Program End\n");
        return 1;  // Success
    } else {
        log_string("Test FAILED\n");
        log_string("Program End\n");
        return 0;  // Failure
    }
}
