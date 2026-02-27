// 52_bst_delete.c
#include <stdio.h>
#include <stdlib.h>
typedef struct Node {
    int val;
    struct Node* left;
    struct Node* right;
} Node;
Node* minValueNode(Node* n) {
    while (n && n->left) n = n->left;
    return n;
}
Node* delete(Node* root, int v) {
    if (!root) return NULL;
    if (v < root->val) root->left = delete(root->left, v);
    else if (v > root->val) root->right = delete(root->right, v);
    else {
        if (!root->left) { Node* t = root->right; free(root); return t; }
        else if (!root->right) { Node* t = root->left; free(root); return t; }
        Node* t = minValueNode(root->right);
        root->val = t->val;
        root->right = delete(root->right, t->val);
    }
    return root;
}
void inorder(Node* root) {
    if (!root) return;
    inorder(root->left);
    printf("%d ", root->val);
    inorder(root->right);
}
int main() {
    Node* root = NULL;
    int vals[5] = {5,3,7,2,4};
    for (int i=0;i<5;i++) root = delete(insert(root, vals[i]), 3);
    inorder(root);
    printf("\n");
    return 0;
}
