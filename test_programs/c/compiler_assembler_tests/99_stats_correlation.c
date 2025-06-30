// 99_stats_correlation.c
#include <stdio.h>
#include <math.h>
#define N 6
double pearson(double* x, double* y, int n) {
    double sx=0, sy=0, sxx=0, syy=0, sxy=0;
    for(int i=0;i<n;i++) {
        sx+=x[i]; sy+=y[i];
        sxx+=x[i]*x[i]; syy+=y[i]*y[i]; sxy+=x[i]*y[i];
    }
    double num = n*sxy - sx*sy;
    double den = sqrt((n*sxx-sx*sx)*(n*syy-sy*sy));
    return num/den;
}
int main() {
    double x[N]={1,2,3,4,5,6}, y[N]={2,4,5,4,5,7};
    printf("Pearson correlation: %.3f\n", pearson(x,y,N));
    return 0;
}
