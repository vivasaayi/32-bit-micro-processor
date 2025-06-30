// 26_union_bitfield.c
#include <stdio.h>
typedef union {
    int i;
    struct { unsigned char b0, b1, b2, b3; } bytes;
} U;
int main() {
    U u; u.i = 0x12345678;
    printf("%02x %02x %02x %02x\n", u.bytes.b0, u.bytes.b1, u.bytes.b2, u.bytes.b3);
    return 0;
}
