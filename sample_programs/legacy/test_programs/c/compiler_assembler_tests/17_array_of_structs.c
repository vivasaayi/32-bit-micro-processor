// 17_array_of_structs.c
#include <stdio.h>
typedef struct { int id; int val; } Item;
int main() {
    Item items[3] = { {1, 10}, {2, 20}, {3, 30} };
    for (int i = 0; i < 3; i++)
        printf("id=%d val=%d\n", items[i].id, items[i].val);
    return 0;
}
