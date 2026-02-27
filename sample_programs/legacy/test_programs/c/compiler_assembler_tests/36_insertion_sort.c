// 36_insertion_sort.c
#include <stdio.h>
#define N 5
int main() {
    int arr[N] = {12, 11, 13, 5, 6};
    for (int i = 1; i < N; i++) {
        int key = arr[i], j = i-1;
        while (j >= 0 && arr[j] > key) {
            arr[j+1] = arr[j];
            j--;
        }
        arr[j+1] = key;
    }
    for (int i = 0; i < N; i++) printf("%d ", arr[i]);
    printf("\n");
    return 0;
}
