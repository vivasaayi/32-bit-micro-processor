/*
 * Comprehensive test of enhanced C compiler features
 * Tests all core JVM-required functionality
 */

/* Test struct definitions */
struct Value {
    int i;
};

struct SimpleJVM {
    int stack_data[4];
    int sp;
    int local_vars[2];
};

int main() {
    /* Test basic variables */
    int x = 10;
    int y = 3;
    
    /* Test arithmetic operations including modulo */
    int sum = x + y;
    int diff = x - y; 
    int product = x * y;
    int quotient = x / y;
    int remainder = x % y;
    
    /* Test array operations */
    int numbers[3];
    numbers[0] = 5;
    numbers[1] = 15;
    numbers[2] = 25;
    
    /* Test struct usage */
    struct Value val;
    val.i = 42;
    
    struct SimpleJVM jvm;
    jvm.sp = 0;
    jvm.local_vars[0] = 100;
    jvm.local_vars[1] = 200;
    
    /* Test sizeof operator */
    int int_size = sizeof(int);
    int struct_size = sizeof(struct Value);
    
    /* Return meaningful result */
    return remainder + val.i;
}
