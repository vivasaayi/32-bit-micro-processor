int main() {
    int arr[5] = {10, 20, 30, 40, 50};
    int* ptr = arr;
    
    int first = *ptr;        // arr[0] = 10
    ptr = ptr + 1;           // Move to next element
    int second = *ptr;       // arr[1] = 20
    ptr = ptr + 2;           // Move to arr[3]
    int fourth = *ptr;       // arr[3] = 40
    
    return first + second + fourth; // 10 + 20 + 40 = 70
}
