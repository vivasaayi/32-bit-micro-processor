// 86_triangle_fill.c
#include <stdio.h>
void set_pixel(int x, int y) { printf("PIXEL %d %d\n", x, y); }
void swap(int* a, int* b) { int t=*a;*a=*b;*b=t; }
void draw_hline(int x0, int x1, int y) { for(int x=x0;x<=x1;x++) set_pixel(x,y); }
void fill_triangle(int x0,int y0,int x1,int y1,int x2,int y2) {
    if(y0>y1){swap(&y0,&y1);swap(&x0,&x1);}
    if(y0>y2){swap(&y0,&y2);swap(&x0,&x2);}
    if(y1>y2){swap(&y1,&y2);swap(&x1,&x2);}
    int total_height = y2 - y0;
    for(int i=0;i<total_height;i++){
        int second_half = i > y1 - y0 || y1 == y0;
        int segment_height = second_half ? y2 - y1 : y1 - y0;
        float alpha = (float)i/total_height;
        float beta  = (float)(i - (second_half ? y1 - y0 : 0))/segment_height;
        int ax = x0 + (x2 - x0) * alpha;
        int bx = second_half ? x1 + (x2 - x1) * beta : x0 + (x1 - x0) * beta;
        if(ax>bx)swap(&ax,&bx);
        draw_hline(ax,bx,y0+i);
    }
}
int main() {
    fill_triangle(2,2, 10,6, 5,12);
    return 0;
}
