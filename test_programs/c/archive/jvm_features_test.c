/*
 * Test program to verify enhanced C compiler features for JVM support
 * Tests: structs, arrays, malloc/free, sizeof, pointers
 */

// Test struct definitions
struct Value {
    int i;
};

struct Stack {
    struct Value items[256];
    int count;
};

// Test malloc and free declarations
int malloc(int size);
void free(int ptr);

// Test function with enhanced features
int test_jvm_features() {
    // Test basic variables
    int x = 10;
    int y = 20;
    
    // Test arithmetic operations including modulo
    int sum = x + y;
    int diff = x - y;
    int product = x * y;
    int quotient = y / x;
    int remainder = y % x;
    
    // Test array declaration and access
    int numbers[5];
    numbers[0] = 1;
    numbers[1] = 2;
    numbers[2] = 3;
    int first = numbers[0];
    
    // Test struct variable and member access
    struct Value val;
    val.i = 42;
    int stored_value = val.i;
    
    // Test struct with array member
    struct Stack stack;
    stack.count = 0;
    stack.items[0].i = 100;
    stack.count = 1;
    
    // Test malloc and sizeof
    int value_size = sizeof(struct Value);
    int ptr = malloc(value_size);
    
    // Test pointer usage (simplified)
    int *num_ptr = &x;
    int deref_value = *num_ptr;
    
    // Test function call with arguments
    // add_numbers(x, y);
    
    // Test control flow
    if (x > 5) {
        x = x + 1;
    }
    
    while (x < 15) {
        x = x + 1;
    }
    
    free(ptr);
    
    return stored_value;
}

int main() {
    int result = test_jvm_features();
    return result;
}
