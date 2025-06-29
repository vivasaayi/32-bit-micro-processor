#include <stdio.h>
#include <stdlib.h>
#define MAX_SIZE 100
#pragma once

int add(int a, int b) {
    return a + b;
}

int main() {
    int result = add(5, 3);
    return result;
}
