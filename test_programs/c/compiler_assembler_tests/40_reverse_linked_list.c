// 40_reverse_linked_list.c
#include <stdio.h>
#include <stdlib.h>
typedef struct Node {
    int val;
    struct Node* next;
} Node;
Node* reverse(Node* head) {
    Node* prev = NULL; Node* curr = head;
    while (curr) {
        Node* next = curr->next;
        curr->next = prev;
        prev = curr;
        curr = next;
    }
    return prev;
}
int main() {
    Node* head = malloc(sizeof(Node));
    head->val = 1; head->next = malloc(sizeof(Node));
    head->next->val = 2; head->next->next = malloc(sizeof(Node));
    head->next->next->val = 3; head->next->next->next = NULL;
    head = reverse(head);
    Node* p = head;
    while (p) { printf("%d ", p->val); p = p->next; }
    printf("\n");
    return 0;
}
