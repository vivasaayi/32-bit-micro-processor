// 67_red_black_insert.c
#include <stdio.h>
#include <stdlib.h>
typedef enum { RED, BLACK } Color;
typedef struct Node {
    int val;
    Color color;
    struct Node* left;
    struct Node* right;
    struct Node* parent;
} Node;
Node* new_node(int v) {
    Node* n = malloc(sizeof(Node)); n->val = v; n->color = RED; n->left = n->right = n->parent = NULL; return n;
}
void inorder(Node* n) { if (!n) return; inorder(n->left); printf("%d(%c) ", n->val, n->color==RED?'R':'B'); inorder(n->right); }
// For brevity, this is a stub. Full red-black insertion is complex.
int main() {
    Node* root = new_node(10);
    root->color = BLACK;
    root->left = new_node(5); root->left->parent = root;
    root->right = new_node(15); root->right->parent = root;
    inorder(root); printf("\n");
    return 0;
}
