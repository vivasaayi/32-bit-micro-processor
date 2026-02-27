/*
 * Very basic test for struct arrays
 */

struct Value {
    int i;
};

int main() {
    struct Value v;
    v.i = 42;
    return v.i;
}
