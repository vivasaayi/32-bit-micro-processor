// 07_pointers.c
#include <stdio.h>
int main() {
    int a = 42;
    int *p = &a;
    printf("Value = %d\n", *p);
    *p = 99;
    printf("New value = %d\n", a);
    return 0;
}
