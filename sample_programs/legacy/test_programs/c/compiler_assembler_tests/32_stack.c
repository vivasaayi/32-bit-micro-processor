// 32_stack.c
#include <stdio.h>
#define N 10
int stack[N], top = -1;
void push(int x) { if (top < N-1) stack[++top] = x; }
int pop() { return (top >= 0) ? stack[top--] : -1; }
int main() {
    push(5); push(10); push(15);
    printf("%d %d %d\n", pop(), pop(), pop());
    return 0;
}
