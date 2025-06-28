/*
 * Test struct array member assignment
 */

struct Test {
    int arr[3];
    int count;
};

int main() {
    struct Test t;
    t.arr[0] = 42;
    return t.arr[0];
}
