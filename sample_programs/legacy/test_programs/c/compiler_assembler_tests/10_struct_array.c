// 10_struct_array.c
#include <stdio.h>
typedef struct { int id; char name[8]; } Item;
int main() {
    Item items[2] = { {1, "foo"}, {2, "bar"} };
    for (int i = 0; i < 2; i++)
        printf("%d: %s\n", items[i].id, items[i].name);
    return 0;
}
