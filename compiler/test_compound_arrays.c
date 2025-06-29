int main() {
    int arr[3];
    arr[0] = 10;
    arr[1] = 20;
    arr[2] = 30;
    
    arr[0] += 5;   // arr[0] = 15
    arr[1] *= 2;   // arr[1] = 40
    arr[2] /= 3;   // arr[2] = 10
    
    int sum = arr[0] + arr[1] + arr[2]; // 15 + 40 + 10 = 65
    return sum;
}
