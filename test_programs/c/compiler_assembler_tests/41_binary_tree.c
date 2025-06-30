// 41_binary_tree.c
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
void inorder(Node* root) {
    if (!root) return;
    inorder(root->left);
    printf("%d ", root->val);
    inorder(root->right);
}
int main() {
    Node* root = new_node(2);
    root->left = new_node(1);
    root->right = new_node(3);
    inorder(root);
    printf("\n");
    return 0;
}
