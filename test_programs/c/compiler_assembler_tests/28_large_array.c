// 28_large_array.c
#include <stdio.h>
#define N 100
int main() {
    int arr[N];
    for (int i = 0; i < N; i++) arr[i] = i*i;
    int sum = 0;
    for (int i = 0; i < N; i++) sum += arr[i];
    printf("sum=%d\n", sum);
    return 0;
}
