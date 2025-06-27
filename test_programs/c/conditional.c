// Conditional logic test
int max(int a, int b) {
    if (a > b) {
        return a;
    } else {
        return b;
    }
}

int main() {
    int x = 15;
    int y = 23;
    int largest = max(x, y);
    
    if (largest > 20) {
        return 1;  // Success
    } else {
        return 0;  // Failure
    }
}
