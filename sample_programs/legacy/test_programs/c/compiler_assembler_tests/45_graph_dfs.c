// 45_graph_dfs.c
#include <stdio.h>
#define N 4
int g[N][N] = {{0,1,1,0},{1,0,1,1},{1,1,0,1},{0,1,1,0}};
int visited[N] = {0};
void dfs(int v) {
    visited[v]=1;
    printf("%d ",v);
    for (int i=0;i<N;i++)
        if (g[v][i] && !visited[i]) dfs(i);
}
int main() {
    dfs(0);
    printf("\n");
    return 0;
}
