// 95_stats_variance_stddev.c
#include <stdio.h>
#include <math.h>
#define N 8
int main() {
    double a[N]={2,4,4,4,5,5,7,9};
    double sum=0, mean, var=0, stddev;
    for(int i=0;i<N;i++) sum+=a[i];
    mean = sum/N;
    for(int i=0;i<N;i++) var += (a[i]-mean)*(a[i]-mean);
    var /= N;
    stddev = sqrt(var);
    printf("mean=%.2f variance=%.2f stddev=%.2f\n", mean, var, stddev);
    return 0;
}
