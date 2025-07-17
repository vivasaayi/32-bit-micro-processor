// 68_trie_insert_search.c
#include <stdio.h>
#include <stdlib.h>
#define ALPHABET 26
typedef struct Trie {
    struct Trie* child[ALPHABET];
    int is_end;
} Trie;
Trie* new_trie() {
    Trie* t = malloc(sizeof(Trie));
    for (int i=0;i<ALPHABET;i++) t->child[i]=NULL;
    t->is_end=0; return t;
}
void insert(Trie* t, const char* s) {
    for (;*s;s++) {
        int idx = *s-'a';
        if (!t->child[idx]) t->child[idx]=new_trie();
        t = t->child[idx];
    }
    t->is_end=1;
}
int search(Trie* t, const char* s) {
    for (;*s;s++) {
        int idx = *s-'a';
        if (!t->child[idx]) return 0;
        t = t->child[idx];
    }
    return t->is_end;
}
int main() {
    Trie* t = new_trie();
    insert(t, "cat");
    insert(t, "car");
    printf("%d %d\n", search(t,"cat"), search(t,"dog"));
    return 0;
}
