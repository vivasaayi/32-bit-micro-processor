// 29_recursive_struct.c
#include <stdio.h>
typedef struct Node {
    int val;
    struct Node* next;
} Node;
int main() {
    Node n1 = {1, 0};
    Node n2 = {2, &n1};
    printf("n2.val=%d n2.next->val=%d\n", n2.val, n2.next->val);
    return 0;
}
