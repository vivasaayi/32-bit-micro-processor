// 90_3d_matrix_transpose.c
#include <stdio.h>
void print_mat(float m[3][3]) {
    for(int i=0;i<3;i++) { for(int j=0;j<3;j++) printf("%6.2f ", m[i][j]); printf("\n"); }
}
void transpose(float m[3][3], float t[3][3]) {
    for(int i=0;i<3;i++) for(int j=0;j<3;j++) t[j][i]=m[i][j];
}
int main() {
    float m[3][3] = {{1,2,3},{4,5,6},{7,8,9}}, t[3][3];
    printf("Original:\n"); print_mat(m);
    transpose(m, t);
    printf("Transposed:\n"); print_mat(t);
    return 0;
}
