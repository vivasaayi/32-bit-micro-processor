// 22_bubble_sort.c
#include <stdio.h>
#define N 5
int main() {
    int arr[N] = {5, 1, 4, 2, 8};
    for (int i = 0; i < N-1; i++)
        for (int j = 0; j < N-i-1; j++)
            if (arr[j] > arr[j+1]) {
                int t = arr[j]; arr[j] = arr[j+1]; arr[j+1] = t;
            }
    for (int i = 0; i < N; i++) printf("%d ", arr[i]);
    printf("\n");
    return 0;
}
