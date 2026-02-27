// Simple pointer arithmetic test for DSA validation
int main() {
    int data[10];  // Static array declaration
    int *ptr = data;
    
    // Initialize some values using pointer arithmetic
    *ptr = 10;        // data[0] = 10
    *(ptr + 1) = 20;  // data[1] = 20
    *(ptr + 2) = 30;  // data[2] = 30
    
    // Sum using pointer arithmetic
    int sum = *ptr + *(ptr + 1) + *(ptr + 2);
    
    // Check result (should be 60)
    int *status = (int*)0x2000;
    if (sum == 60) {
        *status = 1;
    } else {
        *status = 0;
    }
    
    return 0;
}
