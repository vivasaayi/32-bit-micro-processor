// 13_for_while.c
#include <stdio.h>
int main() {
    int i = 0, sum = 0;
    for (i = 0; i < 5; i++) sum += i;
    printf("For sum = %d\n", sum);
    sum = 0; i = 0;
    while (i < 5) { sum += i; i++; }
    printf("While sum = %d\n", sum);
    return 0;
}
