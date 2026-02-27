// Simple array sum test for DSA validation
int main() {
    int arr[5];
    arr[0] = 10;
    arr[1] = 20;
    arr[2] = 30;
    arr[3] = 40;
    arr[4] = 50;
    
    int sum = 0;
    int i = 0;
    while (i < 5) {
        sum = sum + arr[i];
        i = i + 1;
    }
    
    // sum should be 150
    int *status = (int*)0x2000;
    if (sum == 150) {
        *status = 1;  // success
    } else {
        *status = 0;  // failure
    }
    
    return 0;
}
