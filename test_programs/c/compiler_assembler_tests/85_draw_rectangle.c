// 85_draw_rectangle.c
#include <stdio.h>
void set_pixel(int x, int y) { printf("PIXEL %d %d\n", x, y); }
void draw_rectangle(int x0, int y0, int x1, int y1) {
    for (int x = x0; x <= x1; x++) { set_pixel(x, y0); set_pixel(x, y1); }
    for (int y = y0+1; y < y1; y++) { set_pixel(x0, y); set_pixel(x1, y); }
}
int main() {
    draw_rectangle(3, 3, 12, 8);
    return 0;
}
