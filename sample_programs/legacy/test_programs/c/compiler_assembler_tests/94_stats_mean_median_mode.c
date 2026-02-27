// 94_stats_mean_median_mode.c
#include <stdio.h>
#include <stdlib.h>
#define N 10
int cmp(const void* a, const void* b) { return (*(int*)a)-(*(int*)b); }
int mode(int* a, int n) {
    int maxc=0, m=a[0];
    for(int i=0;i<n;i++) {
        int c=1;
        for(int j=i+1;j<n;j++) if(a[j]==a[i]) c++;
        if(c>maxc) { maxc=c; m=a[i]; }
    }
    return m;
}
int main() {
    int a[N]={1,2,2,3,4,5,5,5,6,7};
    double sum=0;
    for(int i=0;i<N;i++) sum+=a[i];
    double mean = sum/N;
    qsort(a,N,sizeof(int),cmp);
    double median = (N%2)?a[N/2]:(a[N/2-1]+a[N/2])/2.0;
    int mo = mode(a,N);
    printf("mean=%.2f median=%.2f mode=%d\n", mean, median, mo);
    return 0;
}
