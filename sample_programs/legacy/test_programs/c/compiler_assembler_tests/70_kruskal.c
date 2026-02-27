// 70_kruskal.c
#include <stdio.h>
#define N 4
int parent[N];
int find(int x) { return parent[x]==x?x:(parent[x]=find(parent[x])); }
void unite(int x,int y) { parent[find(x)]=find(y); }
int main() {
    int edges[5][3] = {{0,1,10},{0,2,6},{0,3,5},{1,3,15},{2,3,4}};
    for(int i=0;i<N;i++) parent[i]=i;
    int mst=0,cnt=0;
    for(int i=0;i<5&&cnt<N-1;i++) {
        int u=edges[i][0],v=edges[i][1],w=edges[i][2];
        if(find(u)!=find(v)) { unite(u,v); mst+=w; cnt++; }
    }
    printf("mst=%d\n",mst);
    return 0;
}
