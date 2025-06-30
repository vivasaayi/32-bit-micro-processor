// 14_global_static.c
#include <stdio.h>
int g = 10;
int f() { static int s = 0; s++; return s; }
int main() {
    printf("g = %d\n", g);
    printf("f() = %d\n", f());
    printf("f() = %d\n", f());
    return 0;
}
