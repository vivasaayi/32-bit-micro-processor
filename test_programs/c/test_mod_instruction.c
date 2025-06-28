// Test program to verify MOD instruction works
// Calculates 17 % 5 = 2

int main() {
    int a = 17;
    int b = 5;
    int result = a % b;  // Should compile to MOD instruction
    
    if (result == 2) {
        return 1;  // Success
    } else {
        return 0;  // Failure
    }
}
