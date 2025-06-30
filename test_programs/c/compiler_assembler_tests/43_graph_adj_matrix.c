// 43_graph_adj_matrix.c
#include <stdio.h>
#define N 3
int main() {
    int g[N][N] = {{0,1,0},{1,0,1},{0,1,0}};
    for (int i=0;i<N;i++) {
        for (int j=0;j<N;j++) printf("%d ",g[i][j]);
        printf("\n");
    }
    return 0;
}
