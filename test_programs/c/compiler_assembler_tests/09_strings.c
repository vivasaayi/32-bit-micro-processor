// 09_strings.c
#include <stdio.h>
#include <string.h>
int main() {
    char s[20] = "abc";
    strcat(s, "def");
    printf("%s\n", s);
    return 0;
}
