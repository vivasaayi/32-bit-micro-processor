// 78_scc_kosaraju.c
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#define N 5
int g[N][N] = {
    {0,1,0,0,0},
    {0,0,1,0,0},
    {1,0,0,1,0},
    {0,0,0,0,1},
    {0,0,0,0,0}
};
int gr[N][N];
int visited[N], order[N], comp[N], ordidx;
void dfs1(int u) {
    visited[u]=1;
    for(int v=0;v<N;v++) if(g[u][v]&&!visited[v]) dfs1(v);
    order[ordidx++]=u;
}
void dfs2(int u, int c) {
    comp[u]=c; visited[u]=1;
    for(int v=0;v<N;v++) if(gr[u][v]&&!visited[v]) dfs2(v,c);
}
int main() {
    memset(gr,0,sizeof(gr));
    for(int u=0;u<N;u++) for(int v=0;v<N;v++) if(g[u][v]) gr[v][u]=1;
    memset(visited,0,sizeof(visited)); ordidx=0;
    for(int i=0;i<N;i++) if(!visited[i]) dfs1(i);
    memset(visited,0,sizeof(visited));
    int c=0;
    for(int i=N-1;i>=0;i--) if(!visited[order[i]]) dfs2(order[i],++c);
    printf("SCCs: ");
    for(int i=0;i<N;i++) printf("%d ",comp[i]);
    printf("\n");
    return 0;
}
