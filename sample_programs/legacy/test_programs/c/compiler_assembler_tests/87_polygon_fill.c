// 87_polygon_fill.c
#include <stdio.h>
#define N 5
void set_pixel(int x, int y) { printf("PIXEL %d %d\n", x, y); }
int min(int a,int b){return a<b?a:b;}
int max(int a,int b){return a>b?a:b;}
void fill_polygon(int px[], int py[], int n) {
    int ymin=py[0], ymax=py[0];
    for(int i=1;i<n;i++) { if(py[i]<ymin)ymin=py[i]; if(py[i]>ymax)ymax=py[i]; }
    for(int y=ymin;y<=ymax;y++) {
        int nodes=0, nodeX[N];
        for(int i=0,j=n-1;i<n;j=i++) {
            if((py[i]<y&&py[j]>=y)||(py[j]<y&&py[i]>=y))
                nodeX[nodes++]=px[i]+(y-py[i])*(px[j]-px[i])/(py[j]-py[i]);
        }
        for(int i=0;i<nodes-1;i++) for(int j=i+1;j<nodes;j++) if(nodeX[i]>nodeX[j]){int t=nodeX[i];nodeX[i]=nodeX[j];nodeX[j]=t;}
        for(int i=0;i<nodes;i+=2) if(i+1<nodes) for(int x=nodeX[i];x<=nodeX[i+1];x++) set_pixel(x,y);
    }
}
int main() {
    int px[N]={5,12,15,10,3}, py[N]={2,4,10,15,8};
    fill_polygon(px,py,N);
    return 0;
}
