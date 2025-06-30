// 23_fibonacci.c
#include <stdio.h>
int fib(int n) { return n <= 1 ? n : fib(n-1) + fib(n-2); }
int main() {
    for (int i = 0; i < 10; i++)
        printf("%d ", fib(i));
    printf("\n");
    return 0;
}
