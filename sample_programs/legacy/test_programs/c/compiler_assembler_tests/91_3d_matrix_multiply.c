// 91_3d_matrix_multiply.c
#include <stdio.h>
void print_mat(float m[3][3]) {
    for(int i=0;i<3;i++) { for(int j=0;j<3;j++) printf("%6.2f ", m[i][j]); printf("\n"); }
}
void multiply(float a[3][3], float b[3][3], float r[3][3]) {
    for(int i=0;i<3;i++) for(int j=0;j<3;j++) {
        r[i][j]=0;
        for(int k=0;k<3;k++) r[i][j]+=a[i][k]*b[k][j];
    }
}
int main() {
    float a[3][3] = {{1,2,3},{4,5,6},{7,8,9}};
    float b[3][3] = {{9,8,7},{6,5,4},{3,2,1}};
    float r[3][3];
    multiply(a,b,r);
    printf("A*B=\n"); print_mat(r);
    return 0;
}
