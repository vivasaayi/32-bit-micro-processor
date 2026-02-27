// 37_linear_search.c
#include <stdio.h>
int linear_search(int* arr, int n, int key) {
    for (int i = 0; i < n; i++)
        if (arr[i] == key) return i;
    return -1;
}
int main() {
    int arr[5] = {2,4,6,8,10};
    printf("%d\n", linear_search(arr,5,8));
    return 0;
}
