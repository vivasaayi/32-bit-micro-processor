// 83_midpoint_ellipse.c
#include <stdio.h>
void set_pixel(int x, int y) { printf("PIXEL %d %d\n", x, y); }
void midpoint_ellipse(int xc, int yc, int rx, int ry) {
    int x = 0, y = ry;
    int rx2 = rx*rx, ry2 = ry*ry;
    int tworx2 = 2*rx2, twory2 = 2*ry2;
    int px = 0, py = tworx2*y;
    set_pixel(xc + x, yc + y); set_pixel(xc - x, yc + y);
    set_pixel(xc + x, yc - y); set_pixel(xc - x, yc - y);
    // Region 1
    int p = ry2 - (rx2*ry) + (0.25*rx2);
    while (px < py) {
        x++;
        px += twory2;
        if (p < 0) p += ry2 + px;
        else { y--; py -= tworx2; p += ry2 + px - py; }
        set_pixel(xc + x, yc + y); set_pixel(xc - x, yc + y);
        set_pixel(xc + x, yc - y); set_pixel(xc - x, yc - y);
    }
    // Region 2
    p = ry2*(x+0.5)*(x+0.5) + rx2*(y-1)*(y-1) - rx2*ry2;
    while (y > 0) {
        y--;
        py -= tworx2;
        if (p > 0) p += rx2 - py;
        else { x++; px += twory2; p += rx2 - py + px; }
        set_pixel(xc + x, yc + y); set_pixel(xc - x, yc + y);
        set_pixel(xc + x, yc - y); set_pixel(xc - x, yc - y);
    }
}
int main() {
    midpoint_ellipse(20, 15, 10, 6);
    return 0;
}
