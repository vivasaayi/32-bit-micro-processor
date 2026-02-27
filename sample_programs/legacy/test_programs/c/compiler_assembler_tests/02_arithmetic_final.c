// Arithmetic test demonstrating dynamic integer logging
void log_int(int value) {
    // Simple iterative approach - build string from right to left
    char digits[12];  // Enough for 32-bit integer
    int i = 0;
    
    // Handle zero case
    if (value == 0) {
        log_string("Value is zero");
        log_string("0");
        return;
    }
    
    // Handle negative numbers
    int is_negative = 0;
    if (value < 0) {
        log_string("Value less than 0");
        is_negative = 1;
        value = 0 - value;  // Convert to positive
    } else {
        log_string("Value is positive");
    }
    
    // Extract digits from right to left
    while (value > 0) {
        digits[i] = '0' + (value % 10);

        log_string(digits[i]);

        value = value / 10;
        i = i + 1;
    }
    
    // Print negative sign if needed
    if (is_negative) {
        log_string("-");
    }
    
    // Print digits from left to right (reverse order)
    while (i > 0) {
        i = i - 1;
        // Convert single character to string and log
        if (digits[i] == '0') log_string("0");
        else if (digits[i] == '1') log_string("1");
        else if (digits[i] == '2') log_string("2");
        else if (digits[i] == '3') log_string("3");
        else if (digits[i] == '4') log_string("4");
        else if (digits[i] == '5') log_string("5");
        else if (digits[i] == '6') log_string("6");
        else if (digits[i] == '7') log_string("7");
        else if (digits[i] == '8') log_string("8");
        else if (digits[i] == '9') log_string("9");
    }
}

int main() {
    int a = 10;
    int b = 3;
    int result;
    
    log_string("=== AAAA Arithmetic Test ===\n");

    log_string("Meeo");
    
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
    
    return result;
}
