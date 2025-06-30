// 35_selection_sort.c
#include <stdio.h>
#define N 5
int main() {
    int arr[N] = {64, 25, 12, 22, 11};
    for (int i = 0; i < N-1; i++) {
        int min = i;
        for (int j = i+1; j < N; j++)
            if (arr[j] < arr[min]) min = j;
        int t = arr[min]; arr[min] = arr[i]; arr[i] = t;
    }
    for (int i = 0; i < N; i++) printf("%d ", arr[i]);
    printf("\n");
    return 0;
}
