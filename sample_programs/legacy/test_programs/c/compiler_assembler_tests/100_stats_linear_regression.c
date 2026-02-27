// 100_stats_linear_regression.c
#include <stdio.h>
#define N 6
void linear_regression(double* x, double* y, int n, double* m, double* b) {
    double sx=0, sy=0, sxx=0, sxy=0;
    for(int i=0;i<n;i++) {
        sx+=x[i]; sy+=y[i];
        sxx+=x[i]*x[i]; sxy+=x[i]*y[i];
    }
    *m = (n*sxy - sx*sy)/(n*sxx - sx*sx);
    *b = (sy - (*m)*sx)/n;
}
int main() {
    double x[N]={1,2,3,4,5,6}, y[N]={2,4,5,4,5,7};
    double m, b;
    linear_regression(x, y, N, &m, &b);
    printf("y = %.2fx + %.2f\n", m, b);
    return 0;
}
