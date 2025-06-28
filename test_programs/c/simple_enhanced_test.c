/*
 * Simple test program for enhanced C compiler features
 */

// Test struct definition
struct Value {
    int i;
};

int main() {
    // Test basic variables
    int x = 10;
    int y = 20;
    
    // Test arithmetic with modulo
    int remainder = y % x;
    
    // Test array
    int numbers[3];
    numbers[0] = 1;
    numbers[1] = 2;
    int first = numbers[0];
    
    // Test struct
    struct Value val;
    val.i = 42;
    int stored = val.i;
    
    // Test sizeof
    int size = sizeof(int);
    
    return stored;
}
