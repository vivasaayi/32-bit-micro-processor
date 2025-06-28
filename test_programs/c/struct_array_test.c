/*
 * Test for struct arrays
 */

struct Value {
    int i;
};

int main() {
    struct Value arr[3];
    arr[0].i = 42;
    return arr[0].i;
}
