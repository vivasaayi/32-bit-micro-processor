// 50_hash_table.c
#include <stdio.h>
#define N 10
int hash(int key) { return key % N; }
int main() {
    int table[N] = {0};
    int keys[5] = {15, 25, 35, 45, 55};
    for (int i = 0; i < 5; i++) {
        int idx = hash(keys[i]);
        table[idx] = keys[i];
    }
    for (int i = 0; i < N; i++)
        if (table[i]) printf("%d:%d ", i, table[i]);
    printf("\n");
    return 0;
}
