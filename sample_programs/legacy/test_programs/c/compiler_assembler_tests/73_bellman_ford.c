// 73_bellman_ford.c
#include <stdio.h>
#define N 5
#define E 8
#define INF 9999
int main() {
    int edges[E][3] = {{0,1,-1},{0,2,4},{1,2,3},{1,3,2},{1,4,2},{3,2,5},{3,1,1},{4,3,-3}};
    int dist[N];
    for(int i=0;i<N;i++) dist[i]=INF;
    dist[0]=0;
    for(int i=1;i<N;i++)
        for(int j=0;j<E;j++)
            if(dist[edges[j][0]]+edges[j][2]<dist[edges[j][1]])
                dist[edges[j][1]]=dist[edges[j][0]]+edges[j][2];
    for(int i=0;i<N;i++) printf("%d ",dist[i]);
    printf("\n");
    return 0;
}
