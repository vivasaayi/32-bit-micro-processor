// 75_topological_sort.c
#include <stdio.h>
#define N 6
int g[N][N] = {{0,1,1,0,0,0},{0,0,0,1,1,0},{0,0,0,0,1,0},{0,0,0,0,0,1},{0,0,0,0,0,1},{0,0,0,0,0,0}};
int visited[N]={0}, stack[N], top=-1;
void dfs(int v) {
    visited[v]=1;
    for(int i=0;i<N;i++) if(g[v][i]&&!visited[i]) dfs(i);
    stack[++top]=v;
}
int main() {
    for(int i=0;i<N;i++) if(!visited[i]) dfs(i);
    while(top>=0) printf("%d ",stack[top--]);
    printf("\n");
    return 0;
}
