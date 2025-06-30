// 12_switch_case.c
#include <stdio.h>
int main() {
    int n = 2;
    switch (n) {
        case 1: printf("one\n"); break;
        case 2: printf("two\n"); break;
        case 3: printf("three\n"); break;
        default: printf("other\n");
    }
    return 0;
}
