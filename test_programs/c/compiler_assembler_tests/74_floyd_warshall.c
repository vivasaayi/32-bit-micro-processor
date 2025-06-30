// 74_floyd_warshall.c
#include <stdio.h>
#define N 4
#define INF 9999
int main() {
    int g[N][N] = {{0,5,INF,10},{INF,0,3,INF},{INF,INF,0,1},{INF,INF,INF,0}};
    for(int k=0;k<N;k++)
        for(int i=0;i<N;i++)
            for(int j=0;j<N;j++)
                if(g[i][k]+g[k][j]<g[i][j]) g[i][j]=g[i][k]+g[k][j];
    for(int i=0;i<N;i++) {
        for(int j=0;j<N;j++) printf("%d ",g[i][j]);
        printf("\n");
    }
    return 0;
}
