// 16_struct_pointer.c
#include <stdio.h>
typedef struct { int x, y; } Point;
int main() {
    Point p = {5, 6};
    Point *pp = &p;
    printf("(%d, %d)\n", pp->x, pp->y);
    return 0;
}
