// 53_tree_height_balance.c
#include <stdio.h>
#include <stdlib.h>
typedef struct Node {
    int val;
    struct Node* left;
    struct Node* right;
} Node;
int height(Node* n) {
    if (!n) return 0;
    int lh = height(n->left), rh = height(n->right);
    return (lh > rh ? lh : rh) + 1;
}
int is_balanced(Node* n) {
    if (!n) return 1;
    int lh = height(n->left), rh = height(n->right);
    if (abs(lh - rh) > 1) return 0;
    return is_balanced(n->left) && is_balanced(n->right);
}
Node* new_node(int v) {
    Node* n = malloc(sizeof(Node)); n->val = v; n->left = n->right = NULL; return n;
}
int main() {
    Node* root = new_node(1);
    root->left = new_node(2);
    root->right = new_node(3);
    root->left->left = new_node(4);
    printf("height=%d balanced=%d\n", height(root), is_balanced(root));
    return 0;
}
