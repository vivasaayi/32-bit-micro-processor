// 49_counting_sort.c
#include <stdio.h>
#define N 6
#define MAX 20
int main() {
    int arr[N]={4,2,2,8,3,3}, out[N], count[MAX]={0};
    for(int i=0;i<N;i++) count[arr[i]]++;
    for(int i=1;i<MAX;i++) count[i]+=count[i-1];
    for(int i=N-1;i>=0;i--) out[--count[arr[i]]]=arr[i];
    for(int i=0;i<N;i++) printf("%d ",out[i]);
    printf("\n");
    return 0;
}
