// 24_string_reverse.c
#include <stdio.h>
#include <string.h>
void reverse(char* s) {
    int n = strlen(s);
    for (int i = 0; i < n/2; i++) {
        char t = s[i]; s[i] = s[n-1-i]; s[n-1-i] = t;
    }
}
int main() {
    char s[16] = "abcdef";
    reverse(s);
    printf("%s\n", s);
    return 0;
}
