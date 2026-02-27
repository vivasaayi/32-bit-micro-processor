int sum4(int* arr) {
    int total = 0;
    total = total + arr[0];
    total = total + arr[1];
    total = total + arr[2];
    total = total + arr[3];
    return total;
}

int main() {
    int values[4] = {3, 1, 4, 2};
    int s = sum4(values);
    return s == 10 ? 0 : 1;
}
