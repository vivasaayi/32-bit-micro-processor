/* Simplified JVM test for our C compiler */

int simple_add(int a, int b) {
    return a + b;
}

int simple_multiply(int a, int b) {
    return a * b;
}

int compute_expression() {
    int val1 = 5;
    int val2 = 3;
    int val3 = 2;
    int result = simple_add(val1, simple_multiply(val2, val3));
    return result;
}

int main() {
    int result = compute_expression();
    return result;
}
