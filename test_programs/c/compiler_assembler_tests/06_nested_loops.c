// 06_nested_loops.c
#include <stdio.h>
int main() {
    int count = 0;
    for (int i = 0; i < 3; i++)
        for (int j = 0; j < 2; j++)
            count++;
    printf("Count = %d\n", count);
    return 0;
}
