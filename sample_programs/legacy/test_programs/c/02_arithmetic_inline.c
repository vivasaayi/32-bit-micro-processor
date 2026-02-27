// Arithmetic test with inline integer logging
// This version puts the log_int logic directly in main

int main() {
    int a = 10;
    int b = 3;
    int result;
    
    log_string("=== Arithmetic Test ===\n");
    
    // Test addition
    result = a + b;
    log_string("10 + 3 = ");
    if (result == 13) {
        log_string("13");
    } else if (result == 0) {
        log_string("0");
    } else {
        log_string("?");
    }
    log_string("\n");
    
    // Test subtraction  
    result = a - b;
    log_string("10 - 3 = ");
    if (result == 7) {
        log_string("7");
    } else if (result == 0) {
        log_string("0");
    } else {
        log_string("?");
    }
    log_string("\n");
    
    // Test multiplication
    result = a * b;
    log_string("10 * 3 = ");
    if (result == 30) {
        log_string("30");
    } else if (result == 0) {
        log_string("0");
    } else {
        log_string("?");
    }
    log_string("\n");
    
    // Test division
    result = a / b;
    log_string("10 / 3 = ");
    if (result == 3) {
        log_string("3");
    } else if (result == 0) {
        log_string("0");
    } else {
        log_string("?");
    }
    log_string("\n");
    
    // Test modulo
    result = a % b;
    log_string("10 % 3 = ");
    if (result == 1) {
        log_string("1");
    } else if (result == 0) {
        log_string("0");
    } else {
        log_string("?");
    }
    log_string("\n");
    
    log_string("All operations completed\n");
    
    // Verify the modulo result specifically
    if (result == 1) {
        log_string("SUCCESS: Final modulo result is 1 as expected\n");
    } else {
        log_string("ERROR: Unexpected modulo result\n");
    }
    
    return result;
}
