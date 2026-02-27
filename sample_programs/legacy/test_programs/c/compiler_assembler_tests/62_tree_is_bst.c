// 62_tree_is_bst.c
#include <stdio.h>
#include <stdlib.h>
typedef struct Node {
    int val;
    struct Node* left;
    struct Node* right;
} Node;
int is_bst_util(Node* n, int min, int max) {
    if (!n) return 1;
    if (n->val < min || n->val > max) return 0;
    return is_bst_util(n->left, min, n->val-1) && is_bst_util(n->right, n->val+1, max);
}
Node* new_node(int v) {
    Node* n = malloc(sizeof(Node)); n->val = v; n->left = n->right = NULL; return n;
}
int main() {
    Node* root = new_node(2);
    root->left = new_node(1);
    root->right = new_node(3);
    printf("is_bst=%d\n", is_bst_util(root, -100, 100));
    return 0;
}
