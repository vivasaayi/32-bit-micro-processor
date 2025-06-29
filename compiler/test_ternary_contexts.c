int max(int a, int b) {
    return (a > b) ? a : b;
}

int main() {
    int arr[3];
    arr[0] = 10;
    arr[1] = 20;
    arr[2] = 15;
    
    // Use ternary in array access
    int index = (arr[0] > arr[1]) ? 0 : 1;
    int maxVal = arr[index];
    
    // Use ternary in function call
    int result = max((arr[0] > arr[2]) ? arr[0] : arr[2], maxVal);
    
    return result;
}
