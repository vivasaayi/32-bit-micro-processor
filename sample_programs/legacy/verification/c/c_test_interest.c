// Interest Calculation Test
// Verifies: Loops, Integer Math, Variables

int main() {
  int principal = 1000;
  int rate = 5; // 5%
  int years = 10;
  int amount = principal;

  // Simple Interest Loop: A = P(1 + rt) ? No, compound is A = P(1+r)^t
  // Using integer math: A = A + (A * rate / 100)
  int i = 0;
  while (i < years) {
    int interest = (amount * rate) / 100;
    amount = amount + interest;
    i++;
  }

  // 1000 * 1.05^10 ~= 1628
  // With integer truncation:
  // Y1: 1000 + 50 = 1050
  // Y2: 1050 + 52 = 1102
  // Y3: 1102 + 55 = 1157
  // ...
  // Let's just check it's > 1500 and < 1700 to be safe against rounding diffs

  if (amount > 1500) {
    if (amount < 1700) {
      return 1; // PASS
    }
  }

  return 0; // FAIL
}
