// 25_struct_func_ptr.c
#include <stdio.h>
typedef struct { int (*op)(int,int); } Math;
int add(int a, int b) { return a+b; }
int main() {
    Math m; m.op = add;
    printf("%d\n", m.op(2,3));
    return 0;
}
