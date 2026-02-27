int mix_math(int x, int y) {
    int p = x * y;
    int q = p / 3;
    int r = p % 7;
    return q + r;
}

int main() {
    int result = mix_math(14, 5);
    return result;
}
