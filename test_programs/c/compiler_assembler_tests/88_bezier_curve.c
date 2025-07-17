// 88_bezier_curve.c
#include <stdio.h>
void set_pixel(int x, int y) { printf("PIXEL %d %d\n", x, y); }
int lerp(int a, int b, float t) { return a + (b - a) * t; }
void bezier(int x0,int y0,int x1,int y1,int x2,int y2,int x3,int y3) {
    for(float t=0;t<=1.0;t+=0.01) {
        float a=1-t,b=t;
        int x = a*a*a*x0 + 3*a*a*b*x1 + 3*a*b*b*x2 + b*b*b*x3;
        int y = a*a*a*y0 + 3*a*a*b*y1 + 3*a*b*b*y2 + b*b*b*y3;
        set_pixel(x,y);
    }
}
int main() {
    bezier(2,2, 8,12, 12,2, 18,10);
    return 0;
}
