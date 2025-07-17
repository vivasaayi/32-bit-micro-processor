/*
 * Simple struct member assignment test
 */

struct Point {
    int x;
    int y;
};

int main() {
    struct Point p;
    p.x = 10;
    return p.x;
}
