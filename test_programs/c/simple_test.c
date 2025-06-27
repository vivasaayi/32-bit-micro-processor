// Simple test without casts
int main() {
    int a = 10;
    int b = 20;
    int sum = a + b;
    int product = a * b;
    if (sum == 30 && product == 200) {
        return 1; // PASS
    } else {
        return 0; // FAIL
    }
}
