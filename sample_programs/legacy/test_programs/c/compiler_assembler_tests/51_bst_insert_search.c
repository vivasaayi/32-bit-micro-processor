// 51_bst_insert_search.c
#include <stdio.h>
#include <stdlib.h>
typedef struct Node {
    int val;
    struct Node* left;
    struct Node* right;
} Node;
Node* insert(Node* root, int v) {
    if (!root) {
        Node* n = malloc(sizeof(Node)); n->val = v; n->left = n->right = NULL; return n;
    }
    if (v < root->val) root->left = insert(root->left, v);
    else root->right = insert(root->right, v);
    return root;
}
int search(Node* root, int v) {
    if (!root) return 0;
    if (root->val == v) return 1;
    if (v < root->val) return search(root->left, v);
    return search(root->right, v);
}
int main() {
    Node* root = NULL;
    int vals[5] = {5,3,7,2,4};
    for (int i=0;i<5;i++) root = insert(root, vals[i]);
    printf("%d %d\n", search(root,4), search(root,6));
    return 0;
}
