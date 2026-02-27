// 38_stack_linked.c
#include <stdio.h>
#include <stdlib.h>
typedef struct Node {
    int val;
    struct Node* next;
} Node;
Node* push(Node* top, int v) {
    Node* n = malloc(sizeof(Node));
    n->val = v; n->next = top;
    return n;
}
Node* pop(Node* top, int* v) {
    if (!top) return NULL;
    *v = top->val;
    Node* n = top->next;
    free(top);
    return n;
}
int main() {
    Node* top = NULL; int v;
    top = push(top, 1); top = push(top, 2);
    top = pop(top, &v); printf("%d ", v);
    top = pop(top, &v); printf("%d\n", v);
    return 0;
}
