// 65_tree_leaf_count.c
#include <stdio.h>
#include <stdlib.h>
typedef struct Node {
    int val;
    struct Node* left;
    struct Node* right;
} Node;
int leaf_count(Node* n) {
    if (!n) return 0;
    if (!n->left && !n->right) return 1;
    return leaf_count(n->left) + leaf_count(n->right);
}
Node* new_node(int v) {
    Node* n = malloc(sizeof(Node)); n->val = v; n->left = n->right = NULL; return n;
}
int main() {
    Node* root = new_node(1);
    root->left = new_node(2);
    root->right = new_node(3);
    root->left->left = new_node(4);
    printf("leaf_count=%d\n", leaf_count(root));
    return 0;
}
