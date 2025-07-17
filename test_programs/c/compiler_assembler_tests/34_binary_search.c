// 34_binary_search.c
#include <stdio.h>
int binary_search(int* arr, int n, int key) {
    int l = 0, r = n-1;
    while (l <= r) {
        int m = (l+r)/2;
        if (arr[m] == key) return m;
        if (arr[m] < key) l = m+1; else r = m-1;
    }
    return -1;
}
int main() {
    int arr[6] = {1,3,5,7,9,11};
    printf("%d\n", binary_search(arr,6,7));
    return 0;
}
