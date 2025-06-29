int main() {
    int arr[5];
    float bad_index = 1.5;
    arr[bad_index] = 42;  // This should cause a type error
    return 0;
}
