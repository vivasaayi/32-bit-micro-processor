// 71_segment_tree.c
#include <stdio.h>
#define N 8
int seg[2*N];
void build(int* arr) {
    for (int i=0;i<N;i++) seg[N+i]=arr[i];
    for (int i=N-1;i>0;i--) seg[i]=seg[2*i]+seg[2*i+1];
}
int query(int l,int r) {
    int res=0;
    for(l+=N,r+=N;l<r;l>>=1,r>>=1) {
        if(l&1) res+=seg[l++];
        if(r&1) res+=seg[--r];
    }
    return res;
}
int main() {
    int arr[N]={1,2,3,4,5,6,7,8};
    build(arr);
    printf("sum(2,6)=%d\n",query(2,6));
    return 0;
}
