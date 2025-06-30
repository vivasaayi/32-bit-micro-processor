// 77_suffix_tree.c
// Naive suffix tree (brute force, for small strings)
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#define MAXLEN 32
struct Node {
    int start, *end;
    struct Node *children[256];
};
struct Node* new_node(int start, int* end) {
    struct Node* n = calloc(1, sizeof(struct Node));
    n->start = start; n->end = end;
    return n;
}
void print_tree(struct Node* n, char* s, int depth) {
    if (!n) return;
    for (int i = 0; i < 256; i++) if (n->children[i]) {
        int l = *(n->children[i]->end) - n->children[i]->start + 1;
        printf("%*s", depth*2, "");
        for (int j = 0; j < l; j++) putchar(s[n->children[i]->start + j]);
        putchar('\n');
        print_tree(n->children[i], s, depth+1);
    }
}
void build_suffix_tree(char* s) {
    int n = strlen(s);
    struct Node* root = new_node(-1, NULL);
    for (int i = 0; i < n; i++) {
        struct Node* cur = root;
        for (int j = i; j < n; j++) {
            if (!cur->children[(unsigned char)s[j]]) {
                int* end = malloc(sizeof(int)); *end = n-1;
                cur->children[(unsigned char)s[j]] = new_node(j, end);
                break;
            } else {
                cur = cur->children[(unsigned char)s[j]];
            }
        }
    }
    printf("Suffix tree for '%s':\n", s);
    print_tree(root, s, 0);
}
int main() {
    char s[MAXLEN] = "banana";
    build_suffix_tree(s);
    return 0;
}
