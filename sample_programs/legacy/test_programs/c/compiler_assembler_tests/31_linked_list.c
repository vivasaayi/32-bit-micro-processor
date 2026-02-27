// 31_linked_list.c
#include <stdio.h>
#include <stdlib.h>
typedef struct Node {
    int val;
    struct Node* next;
} Node;
int main() {
    Node* head = malloc(sizeof(Node));
    head->val = 1; head->next = malloc(sizeof(Node));
    head->next->val = 2; head->next->next = NULL;
    Node* p = head;
    while (p) { printf("%d ", p->val); p = p->next; }
    printf("\n");
    return 0;
}
