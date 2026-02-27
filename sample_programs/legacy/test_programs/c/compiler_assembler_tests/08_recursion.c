// 08_recursion.c
#include <stdio.h>
int fact(int n) { return n <= 1 ? 1 : n * fact(n-1); }
int main() {
    printf("5! = %d\n", fact(5));
    return 0;
}
