int calculate(int base, int increment) {
    base += increment * 2;
    return base;
}

int main() {
    int arr[4];
    arr[0] = 10;
    arr[1] = 20;
    arr[2] = 30;
    arr[3] = 40;
    
    // Use compound assignments in various contexts
    arr[0] += calculate(5, 3);      // arr[0] += calculate(5, 3) = 10 + 11 = 21
    arr[1] *= (arr[0] > 20) ? 2 : 1; // arr[1] *= 2 = 40
    arr[2] -= arr[1] / 4;           // arr[2] -= 10 = 20
    
    int total = 0;
    total += arr[0];  // 21
    total += arr[1];  // 21 + 40 = 61
    total += arr[2];  // 61 + 20 = 81
    total += arr[3];  // 81 + 40 = 121
    
    return total;
}
