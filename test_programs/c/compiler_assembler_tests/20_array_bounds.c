// 20_array_bounds.c
#include <stdio.h>
int main() {
    int arr[4] = {0,1,2,3};
    for (int i = 0; i < 6; i++)
        printf("arr[%d]=%d\n", i, arr[i]);
    return 0;
}
