// 60_list_middle.c
#include <stdio.h>
#include <stdlib.h>
typedef struct Node {
    int val;
    struct Node* next;
} Node;
int find_middle(Node* head) {
    Node* slow = head, *fast = head;
    while (fast && fast->next) {
        slow = slow->next;
        fast = fast->next->next;
    }
    return slow ? slow->val : -1;
}
int main() {
    Node* head = malloc(sizeof(Node));
    head->val = 1; head->next = malloc(sizeof(Node));
    head->next->val = 2; head->next->next = malloc(sizeof(Node));
    head->next->next->val = 3; head->next->next->next = malloc(sizeof(Node));
    head->next->next->next->val = 4; head->next->next->next->next = NULL;
    printf("%d\n", find_middle(head));
    return 0;
}
