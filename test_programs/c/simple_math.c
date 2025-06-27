// Simple arithmetic test

int main() {
    int a = 10;
    int b = 20;
    int sum = a + b;
    int product = a * b;
    // Write to memory address 0x2000 directly
    if (sum == 30 && product == 200) {
        ((int*)0x2000)[0] = 1; // PASS
    } else {
        ((int*)0x2000)[0] = 0; // FAIL
    }
    return 0;
}
