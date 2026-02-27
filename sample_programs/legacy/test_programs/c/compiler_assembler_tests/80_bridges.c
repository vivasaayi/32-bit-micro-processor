// 80_bridges.c
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
int visited[N], disc[N], low[N], parent[N], timec;
void dfs(int u) {
    visited[u]=1;
    disc[u]=low[u]=++timec;
    for(int v=0;v<N;v++) if(g[u][v]) {
        if(!visited[v]) {
            parent[v]=u;
            dfs(v);
            low[u]=low[u]<low[v]?low[u]:low[v];
            if(low[v]>disc[u]) printf("Bridge: %d-%d\n",u,v);
        } else if(v!=parent[u]) low[u]=low[u]<disc[v]?low[u]:disc[v];
    }
}
int main() {
    memset(visited,0,sizeof(visited));
    memset(parent,-1,sizeof(parent));
    timec=0;
    for(int i=0;i<N;i++) if(!visited[i]) dfs(i);
    return 0;
}
