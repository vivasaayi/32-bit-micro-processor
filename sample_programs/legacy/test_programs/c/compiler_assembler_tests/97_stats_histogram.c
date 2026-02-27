// 97_stats_histogram.c
#include <stdio.h>
#define N 12
int main() {
    int a[N]={1,2,2,3,3,3,4,4,4,4,5,5};
    int hist[6]={0};
    for(int i=0;i<N;i++) hist[a[i]]++;
    for(int i=1;i<=5;i++) {
        printf("%d: ",i);
        for(int j=0;j<hist[i];j++) printf("*");
        printf("\n");
    }
    return 0;
}
