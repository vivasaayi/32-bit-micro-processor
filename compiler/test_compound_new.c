int main() {
    int x = 10;
    int y = 5;
    
    x += 5;     // x = 15
    y %= 3;     // y = 2
    x &= 7;     // x = 7 & 15 = 7
    y |= 8;     // y = 2 | 8 = 10
    x ^= 3;     // x = 7 ^ 3 = 4
    y <<= 1;    // y = 10 << 1 = 20
    x >>= 1;    // x = 4 >> 1 = 2
    
    return x + y; // 2 + 20 = 22
}
