// 54_tree_mirror.c
#include <stdio.h>
#include <stdlib.h>
typedef struct Node {
    int val;
    struct Node* left;
    struct Node* right;
} Node;
void mirror(Node* n) {
    if (!n) return;
    Node* t = n->left; n->left = n->right; n->right = t;
    mirror(n->left); mirror(n->right);
}
void inorder(Node* n) {
    if (!n) return;
    inorder(n->left); printf("%d ", n->val); inorder(n->right);
}
Node* new_node(int v) {
    Node* n = malloc(sizeof(Node)); n->val = v; n->left = n->right = NULL; return n;
}
int main() {
    Node* root = new_node(1);
    root->left = new_node(2);
    root->right = new_node(3);
    mirror(root);
    inorder(root);
    printf("\n");
    return 0;
}
