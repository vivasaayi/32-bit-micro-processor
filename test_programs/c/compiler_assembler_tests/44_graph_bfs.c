// 44_graph_bfs.c
#include <stdio.h>
#define N 4
int g[N][N] = {{0,1,1,0},{1,0,1,1},{1,1,0,1},{0,1,1,0}};
int q[N], front=0, rear=0, visited[N]={0};
void enqueue(int v) { q[rear++] = v; }
int dequeue() { return q[front++]; }
int empty() { return front == rear; }
void bfs(int s) {
    enqueue(s); visited[s]=1;
    while (!empty()) {
        int v = dequeue();
        printf("%d ",v);
        for (int i=0;i<N;i++)
            if (g[v][i] && !visited[i]) { enqueue(i); visited[i]=1; }
    }
}
int main() {
    bfs(0);
    printf("\n");
    return 0;
}
