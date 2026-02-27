// Factorial computation
int factorial(int n) {
    int result = 1;
    while (n > 1) {
        result = result * n;
        n = n - 1;
    }
    return result;
}

int main() {
    int fact5 = factorial(5);
    return fact5;
}
