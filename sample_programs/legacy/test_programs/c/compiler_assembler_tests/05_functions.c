// 05_functions.c
#include <stdio.h>
int add(int a, int b) { return a + b; }
int main() {
    int result = add(7, 5);
    printf("7 + 5 = %d\n", result);
    return 0;
}
