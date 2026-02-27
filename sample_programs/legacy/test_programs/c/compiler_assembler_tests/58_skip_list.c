// 58_skip_list.c
#include <stdio.h>
#include <stdlib.h>
#define MAX_LEVEL 3

typedef struct Node {
    int val;
    struct Node* next[MAX_LEVEL];
} Node;
Node* new_node(int v) {
    Node* n = malloc(sizeof(Node)); n->val = v;
    for (int i=0;i<MAX_LEVEL;i++) n->next[i]=NULL;
    return n;
}
int main() {
    Node* head = new_node(-1);
    Node* n1 = new_node(1), *n2 = new_node(2), *n3 = new_node(3);
    head->next[0]=n1; n1->next[0]=n2; n2->next[0]=n3;
    for (Node* p = head->next[0]; p; p = p->next[0]) printf("%d ", p->val);
    printf("\n");
    return 0;
}
