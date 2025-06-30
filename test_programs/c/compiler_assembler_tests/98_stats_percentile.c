// 98_stats_percentile.c
#include <stdio.h>
#include <stdlib.h>
#define N 10
int cmp(const void* a, const void* b) { return (*(int*)a)-(*(int*)b); }
double percentile(int* a, int n, double p) {
    qsort(a, n, sizeof(int), cmp);
    double idx = p * (n-1);
    int i = (int)idx;
    if (i == n-1) return a[n-1];
    return a[i] + (a[i+1]-a[i])*(idx-i);
}
int main() {
    int a[N] = {1,2,3,4,5,6,7,8,9,10};
    printf("25th percentile: %.2f\n", percentile(a,N,0.25));
    printf("50th percentile: %.2f\n", percentile(a,N,0.5));
    printf("90th percentile: %.2f\n", percentile(a,N,0.9));
    return 0;
}
