// 30_var_args.c
#include <stdio.h>
#include <stdarg.h>
void printsum(int n, ...) {
    va_list ap;
    va_start(ap, n);
    int sum = 0;
    for (int i = 0; i < n; i++) sum += va_arg(ap, int);
    va_end(ap);
    printf("sum=%d\n", sum);
}
int main() {
    printsum(3, 1, 2, 3);
    return 0;
}
