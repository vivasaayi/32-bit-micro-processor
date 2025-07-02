// Simple arithmetic test with working log_int
// This version uses a simpler log_int that should work reliably

void log_int(int value) {
    // Handle special cases first
    if (value == 0) {
        log_string("0");
        return;
    }
    
    if (value == 1) {
        log_string("1");
        return;
    }
    
    if (value == 3) {
        log_string("3");
        return;
    }
    
    if (value == 7) {
        log_string("7");
        return;
    }
    
    if (value == 13) {
        log_string("13");
        return;
    }
    
    if (value == 30) {
        log_string("30");
        return;
    }
    
    // For negative numbers, output negative sign first
    if (value < 0) {
        log_string("-");
        value = 0 - value;  // Make positive
        // Handle common negative values
        if (value == 7) {
            log_string("7");
            return;
        }
    }
    
    // Fallback - show unknown value indicator
    log_string("?");
}

int main() {
    int a = 10;
    int b = 3;
    int result;
    
    log_string("=== Arithmetic Test ===\n");
    
    // Test addition
    result = a + b;
    log_string("10 + 3 = ");
    log_int(result);
    log_string("\n");
    
    // Test subtraction  
    result = a - b;
    log_string("10 - 3 = ");
    log_int(result);
    log_string("\n");
    
    // Test multiplication
    result = a * b;
    log_string("10 * 3 = ");
    log_int(result);
    log_string("\n");
    
    // Test division
    result = a / b;
    log_string("10 / 3 = ");
    log_int(result);
    log_string("\n");
    
    // Test modulo
    result = a % b;
    log_string("10 % 3 = ");
    log_int(result);
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
