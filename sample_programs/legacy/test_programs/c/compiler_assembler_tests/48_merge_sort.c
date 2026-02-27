// 48_merge_sort.c
#include <stdio.h>
#define N 6
void merge(int arr[], int l, int m, int r) {
    int n1 = m-l+1, n2 = r-m;
    int L[10], R[10];
    for (int i=0;i<n1;i++) L[i]=arr[l+i];
    for (int i=0;i<n2;i++) R[i]=arr[m+1+i];
    int i=0,j=0,k=l;
    while(i<n1&&j<n2) arr[k++]=L[i]<R[j]?L[i++]:R[j++];
    while(i<n1) arr[k++]=L[i++];
    while(j<n2) arr[k++]=R[j++];
}
void merge_sort(int arr[], int l, int r) {
    if (l<r) {
        int m=(l+r)/2;
        merge_sort(arr,l,m);
        merge_sort(arr,m+1,r);
        merge(arr,l,m,r);
    }
}
int main() {
    int arr[N]={12,11,13,5,6,7};
    merge_sort(arr,0,N-1);
    for(int i=0;i<N;i++) printf("%d ",arr[i]);
    printf("\n");
    return 0;
}
