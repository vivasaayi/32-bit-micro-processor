// 79_articulation_points.c
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#define N 5
int g[N][N] = {
    {0,1,1,0,0},
    {1,0,1,1,0},
    {1,1,0,1,1},
    {0,1,1,0,1},
    {0,0,1,1,0}
};
int visited[N], disc[N], low[N], parent[N], ap[N], timec;
void dfs(int u) {
    int children=0;
    visited[u]=1;
    disc[u]=low[u]=++timec;
    for(int v=0;v<N;v++) if(g[u][v]) {
        if(!visited[v]) {
            children++; parent[v]=u;
            dfs(v);
            low[u]=low[u]<low[v]?low[u]:low[v];
            if(parent[u]==-1&&children>1) ap[u]=1;
            if(parent[u]!=-1&&low[v]>=disc[u]) ap[u]=1;
        } else if(v!=parent[u]) low[u]=low[u]<disc[v]?low[u]:disc[v];
    }
}
int main() {
    memset(visited,0,sizeof(visited));
    memset(parent,-1,sizeof(parent));
    memset(ap,0,sizeof(ap));
    timec=0;
    for(int i=0;i<N;i++) if(!visited[i]) dfs(i);
    printf("Articulation points: ");
    for(int i=0;i<N;i++) if(ap[i]) printf("%d ",i);
    printf("\n");
    return 0;
}
