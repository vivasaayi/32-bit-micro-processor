// 84_flood_fill.c
#include <stdio.h>
#define W 10
#define H 10
int img[H][W];
void set_pixel(int x, int y) { img[y][x] = 1; }
void print_img() { for(int y=0;y<H;y++){for(int x=0;x<W;x++)printf("%c",img[y][x]?"#":".");printf("\n");}}
void flood_fill(int x, int y) {
    if (x<0||x>=W||y<0||y>=H||img[y][x]) return;
    set_pixel(x, y);
    flood_fill(x+1, y); flood_fill(x-1, y); flood_fill(x, y+1); flood_fill(x, y-1);
}
int main() {
    for(int y=0;y<H;y++)for(int x=0;x<W;x++)img[y][x]=0;
    set_pixel(5,5); set_pixel(5,6); set_pixel(6,5); // block
    flood_fill(0,0);
    print_img();
    return 0;
}
