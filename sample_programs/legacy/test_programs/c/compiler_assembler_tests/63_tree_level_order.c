// 63_tree_level_order.c
#include <stdio.h>
#include <stdlib.h>
#define MAXQ 100
typedef struct Node {
    int val;
    struct Node* left;
    struct Node* right;
} Node;
Node* new_node(int v) {
    Node* n = malloc(sizeof(Node)); n->val = v; n->left = n->right = NULL; return n;
}
void level_order(Node* root) {
    Node* q[MAXQ]; int front=0, rear=0;
    if (!root) return;
    q[rear++] = root;
    while (front < rear) {
        Node* n = q[front++];
        printf("%d ", n->val);
        if (n->left) q[rear++] = n->left;
        if (n->right) q[rear++] = n->right;
    }
}
int main() {
    Node* root = new_node(1);
    root->left = new_node(2);
    root->right = new_node(3);
    root->left->left = new_node(4);
    level_order(root);
    printf("\n");
    return 0;
}
