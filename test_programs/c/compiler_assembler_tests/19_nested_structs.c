// 19_nested_structs.c
#include <stdio.h>
typedef struct { int x; int y; } Point;
typedef struct { Point p1; Point p2; } Line;
int main() {
    Line l = { {1,2}, {3,4} };
    printf("(%d,%d)-(%d,%d)\n", l.p1.x, l.p1.y, l.p2.x, l.p2.y);
    return 0;
}
