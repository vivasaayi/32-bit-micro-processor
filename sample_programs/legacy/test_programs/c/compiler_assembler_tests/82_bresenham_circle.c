// 82_bresenham_circle.c
#include <stdio.h>
void set_pixel(int x, int y) { printf("PIXEL %d %d\n", x, y); }
void bresenham_circle(int xc, int yc, int r) {
    int x = 0, y = r, d = 3 - 2 * r;
    while (y >= x) {
        set_pixel(xc + x, yc + y); set_pixel(xc - x, yc + y);
        set_pixel(xc + x, yc - y); set_pixel(xc - x, yc - y);
        set_pixel(xc + y, yc + x); set_pixel(xc - y, yc + x);
        set_pixel(xc + y, yc - x); set_pixel(xc - y, yc - x);
        x++;
        if (d > 0) { y--; d = d + 4 * (x - y) + 10; }
        else d = d + 4 * x + 6;
    }
}
int main() {
    bresenham_circle(10, 10, 8);
    return 0;
}
