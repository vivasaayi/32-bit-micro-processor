// 56_doubly_linked_list.c
#include <stdio.h>
#include <stdlib.h>
typedef struct Node {
    int val;
    struct Node* prev;
    struct Node* next;
} Node;
Node* append(Node* head, int v) {
    Node* n = malloc(sizeof(Node)); n->val = v; n->next = NULL;
    if (!head) { n->prev = NULL; return n; }
    Node* p = head;
    while (p->next) p = p->next;
    p->next = n; n->prev = p;
    return head;
}
void print_forward(Node* head) {
    for (Node* p = head; p; p = p->next) printf("%d ", p->val);
    printf("\n");
}
void print_backward(Node* head) {
    Node* p = head;
    while (p && p->next) p = p->next;
    for (; p; p = p->prev) printf("%d ", p->val);
    printf("\n");
}
int main() {
    Node* head = NULL;
    head = append(head, 1); head = append(head, 2); head = append(head, 3);
    print_forward(head);
    print_backward(head);
    return 0;
}
