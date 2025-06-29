int factorial(int n) {
    if (n <= 1) {
        return 1;
    }
    return n * factorial(n - 1);
}

int fibonacci(int n) {
    if (n <= 1) {
        return n;
    }
    return fibonacci(n - 1) + fibonacci(n - 2);
}

int main() {
    int fact5 = factorial(5);
    int fib10 = fibonacci(10);
    int sum = fact5 + fib10;
    return sum;
}
