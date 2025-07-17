// 96_stats_min_max_range.c
#include <stdio.h>
#define N 7
int main() {
    int a[N]={8,3,5,1,9,2,7};
    int min=a[0], max=a[0];
    for(int i=1;i<N;i++) {
        if(a[i]<min) min=a[i];
        if(a[i]>max) max=a[i];
    }
    printf("min=%d max=%d range=%d\n", min, max, max-min);
    return 0;
}
