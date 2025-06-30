// 61_tree_lca.c
#include <stdio.h>
#include <stdlib.h>
typedef struct Node {
    int val;
    struct Node* left;
    struct Node* right;
} Node;
Node* new_node(int v) {
    Node* n = malloc(sizeof(Node)); n->val = v; n->left = n->right = NULL; return n;
}
Node* lca(Node* root, int n1, int n2) {
    if (!root) return NULL;
    if (root->val == n1 || root->val == n2) return root;
    Node* l = lca(root->left, n1, n2);
    Node* r = lca(root->right, n1, n2);
    if (l && r) return root;
    return l ? l : r;
}
int main() {
    Node* root = new_node(3);
    root->left = new_node(5);
    root->right = new_node(1);
    root->left->left = new_node(6);
    root->left->right = new_node(2);
    Node* res = lca(root, 6, 2);
    printf("lca=%d\n", res ? res->val : -1);
    return 0;
}
