// 15_pointer_arith.c
#include <stdio.h>
int main() {
    int arr[3] = {10, 20, 30};
    int *p = arr;
    printf("*p = %d\n", *p);
    p++;
    printf("*(p+1) = %d\n", *p);
    return 0;
}
