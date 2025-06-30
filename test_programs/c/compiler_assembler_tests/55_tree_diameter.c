// 55_tree_diameter.c
#include <stdio.h>
#include <stdlib.h>
typedef struct Node {
    int val;
    struct Node* left;
    struct Node* right;
} Node;
int max(int a, int b) { return a > b ? a : b; }
int diameter(Node* n, int* h) {
    if (!n) { *h = 0; return 0; }
    int lh, rh;
    int ld = diameter(n->left, &lh);
    int rd = diameter(n->right, &rh);
    *h = (lh > rh ? lh : rh) + 1;
    return max(lh+rh+1, max(ld, rd));
}
Node* new_node(int v) {
    Node* n = malloc(sizeof(Node)); n->val = v; n->left = n->right = NULL; return n;
}
int main() {
    Node* root = new_node(1);
    root->left = new_node(2);
    root->right = new_node(3);
    root->left->left = new_node(4);
    int h = 0;
    printf("diameter=%d\n", diameter(root, &h));
    return 0;
}
