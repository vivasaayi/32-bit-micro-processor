// 47_quick_sort.c
#include <stdio.h>
#define N 5
void quick_sort(int arr[], int l, int r) {
    if (l >= r) return;
    int p = arr[r], i = l-1;
    for (int j = l; j < r; j++)
        if (arr[j] < p) { int t = arr[++i]; arr[i] = arr[j]; arr[j] = t; }
    int t = arr[i+1]; arr[i+1] = arr[r]; arr[r] = t;
    quick_sort(arr, l, i);
    quick_sort(arr, i+2, r);
}
int main() {
    int arr[N] = {10, 7, 8, 9, 1};
    quick_sort(arr, 0, N-1);
    for (int i = 0; i < N; i++) printf("%d ", arr[i]);
    printf("\n");
    return 0;
}
