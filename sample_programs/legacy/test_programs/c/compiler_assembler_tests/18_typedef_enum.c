// 18_typedef_enum.c
#include <stdio.h>
typedef enum { RED, GREEN, BLUE } Color;
int main() {
    Color c = GREEN;
    if (c == GREEN) printf("green\n");
    return 0;
}
