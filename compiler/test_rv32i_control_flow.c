int main() {
    int a = 5;
    int b = 9;
    int acc = 0;

    if (a < b) {
        acc = acc + 10;
    } else {
        acc = acc - 10;
    }

    int i = 0;
    while (i < 4) {
        acc = acc + i;
        i = i + 1;
    }

    int j = 0;
    for (j = 0; j < 3; j = j + 1) {
        acc = acc ^ j;
    }

    acc = (acc << 1) | (b & 3);
    return acc;
}
