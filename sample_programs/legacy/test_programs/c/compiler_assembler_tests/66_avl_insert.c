// 66_avl_insert.c
#include <stdio.h>
#include <stdlib.h>
typedef struct Node {
    int val, height;
    struct Node* left;
    struct Node* right;
} Node;
int max(int a, int b) { return a > b ? a : b; }
int height(Node* n) { return n ? n->height : 0; }
Node* new_node(int v) {
    Node* n = malloc(sizeof(Node)); n->val = v; n->left = n->right = NULL; n->height = 1; return n;
}
Node* right_rotate(Node* y) {
    Node* x = y->left; Node* T2 = x->right;
    x->right = y; y->left = T2;
    y->height = max(height(y->left), height(y->right)) + 1;
    x->height = max(height(x->left), height(x->right)) + 1;
    return x;
}
Node* left_rotate(Node* x) {
    Node* y = x->right; Node* T2 = y->left;
    y->left = x; x->right = T2;
    x->height = max(height(x->left), height(x->right)) + 1;
    y->height = max(height(y->left), height(y->right)) + 1;
    return y;
}
int get_balance(Node* n) { return n ? height(n->left) - height(n->right) : 0; }
Node* insert(Node* n, int v) {
    if (!n) return new_node(v);
    if (v < n->val) n->left = insert(n->left, v);
    else if (v > n->val) n->right = insert(n->right, v);
    else return n;
    n->height = 1 + max(height(n->left), height(n->right));
    int balance = get_balance(n);
    if (balance > 1 && v < n->left->val) return right_rotate(n);
    if (balance < -1 && v > n->right->val) return left_rotate(n);
    if (balance > 1 && v > n->left->val) { n->left = left_rotate(n->left); return right_rotate(n); }
    if (balance < -1 && v < n->right->val) { n->right = right_rotate(n->right); return left_rotate(n); }
    return n;
}
void inorder(Node* n) { if (!n) return; inorder(n->left); printf("%d ", n->val); inorder(n->right); }
int main() {
    Node* root = NULL;
    int vals[6] = {10, 20, 30, 40, 50, 25};
    for (int i=0;i<6;i++) root = insert(root, vals[i]);
    inorder(root); printf("\n");
    return 0;
}
