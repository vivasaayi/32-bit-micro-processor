/*
 * Test struct with array member assignment
 */

struct Test {
    int arr[3];
    int count;
};

int main() {
    struct Test t;
    t.count = 1;
    return t.count;
}
