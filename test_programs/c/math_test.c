// Simple test with memory status writing
int main() {
    int a = 10;
    int b = 20;
    int sum = a + b;
    int product = a * b;
    
    // Write values to memory for testing
    int* ptr1 = (int*)0x1000;
    int* ptr2 = (int*)0x1004;
    int* ptr3 = (int*)0x1008;
    int* ptr4 = (int*)0x100C;
    
    *ptr1 = 10000;
    *ptr2 = 30000;
    *ptr3 = 50000;
    
    if (sum == 30 && product == 200) {
        *ptr4 = 80000;  // Expected value for pass
        return 1;
    } else {
        *ptr4 = 99999;  // Wrong value for fail
        return 0;
    }
}
