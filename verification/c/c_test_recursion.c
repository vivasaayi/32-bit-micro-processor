// Recursion Test (Factorial)
// Verifies: Stack Application, Function Calls, Save/Restore Registers

int factorial(int n) {
  if (n <= 1)
    return 1;
  return n * factorial(n - 1);
}

int main() {
  int result = factorial(5); // 120

  if (result == 120) {
    return 1;
  }
  return 0;
}
