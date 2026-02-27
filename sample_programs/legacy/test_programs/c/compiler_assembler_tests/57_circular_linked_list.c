// 57_circular_linked_list.c
#include <stdio.h>
#include <stdlib.h>
typedef struct Node {
    int val;
    struct Node* next;
} Node;
Node* append(Node* head, int v) {
    Node* n = malloc(sizeof(Node)); n->val = v;
    if (!head) { n->next = n; return n; }
    Node* p = head;
    while (p->next != head) p = p->next;
    p->next = n; n->next = head;
    return head;
}
void print_list(Node* head) {
    if (!head) return;
    Node* p = head;
    do { printf("%d ", p->val); p = p->next; } while (p != head);
    printf("\n");
}
int main() {
    Node* head = NULL;
    head = append(head, 1); head = append(head, 2); head = append(head, 3);
    print_list(head);
    return 0;
}
