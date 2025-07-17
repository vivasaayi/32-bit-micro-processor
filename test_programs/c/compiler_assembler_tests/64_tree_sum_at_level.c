// 64_tree_sum_at_level.c
#include <stdio.h>
#include <stdlib.h>
#define MAXQ 100
typedef struct Node {
    int val;
    struct Node* left;
    struct Node* right;
} Node;
Node* new_node(int v) {
    Node* n = malloc(sizeof(Node)); n->val = v; n->left = n->right = NULL; return n;
}
int sum_at_level(Node* root, int level) {
    if (!root) return 0;
    if (level == 0) return root->val;
    return sum_at_level(root->left, level-1) + sum_at_level(root->right, level-1);
}
int main() {
    Node* root = new_node(1);
    root->left = new_node(2);
    root->right = new_node(3);
    root->left->left = new_node(4);
    printf("sum_at_level_2=%d\n", sum_at_level(root,2));
    return 0;
}
