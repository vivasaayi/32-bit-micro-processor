// 69_dijkstra.c
#include <stdio.h>
#define N 4
#define INF 9999
int main() {
    int g[N][N] = {{0,5,INF,10},{INF,0,3,INF},{INF,INF,0,1},{INF,INF,INF,0}};
    int dist[N], visited[N]={0}, src=0;
    for(int i=0;i<N;i++) dist[i]=g[src][i];
    visited[src]=1;
    for(int c=1;c<N;c++) {
        int min=INF,u=-1;
        for(int i=0;i<N;i++) if(!visited[i]&&dist[i]<min) {min=dist[i];u=i;}
        if(u==-1) break;
        visited[u]=1;
        for(int v=0;v<N;v++) if(!visited[v]&&dist[u]+g[u][v]<dist[v]) dist[v]=dist[u]+g[u][v];
    }
    for(int i=0;i<N;i++) printf("%d ",dist[i]);
    printf("\n");
    return 0;
}
