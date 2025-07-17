// 76_segment_tree.c
#include <stdio.h>
#include <stdlib.h>
#define N 8
int arr[N] = {1, 3, 5, 7, 9, 11, 13, 15};
int seg[2*N];
void build() {
    for (int i = 0; i < N; i++) seg[N+i] = arr[i];
    for (int i = N-1; i > 0; --i) seg[i] = seg[i<<1] + seg[i<<1|1];
}
void update(int idx, int value) {
    idx += N;
    seg[idx] = value;
    for (idx >>= 1; idx > 0; idx >>= 1)
        seg[idx] = seg[idx<<1] + seg[idx<<1|1];
}
int query(int l, int r) { // [l, r)
    int res = 0;
    for (l += N, r += N; l < r; l >>= 1, r >>= 1) {
        if (l&1) res += seg[l++];
        if (r&1) res += seg[--r];
    }
    return res;
}
int main() {
    build();
    printf("Sum [0,8) = %d\n", query(0,8));
    printf("Sum [1,5) = %d\n", query(1,5));
    update(2, 10);
    printf("After update: Sum [0,8) = %d\n", query(0,8));
    return 0;
}
