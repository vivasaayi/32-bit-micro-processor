// 81_bresenham_line.c
#include <stdio.h>
void set_pixel(int x, int y) { printf("PIXEL %d %d\n", x, y); }
void bresenham_line(int x0, int y0, int x1, int y1) {
    int dx = abs(x1 - x0), sx = x0 < x1 ? 1 : -1;
    int dy = -abs(y1 - y0), sy = y0 < y1 ? 1 : -1;
    int err = dx + dy, e2;
    while (1) {
        set_pixel(x0, y0);
        if (x0 == x1 && y0 == y1) break;
        e2 = 2 * err;
        if (e2 >= dy) { err += dy; x0 += sx; }
        if (e2 <= dx) { err += dx; y0 += sy; }
    }
}
int main() {
    bresenham_line(2, 2, 10, 6);
    bresenham_line(0, 0, 7, 15);
    return 0;
}
