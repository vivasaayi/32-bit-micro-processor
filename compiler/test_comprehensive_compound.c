/* Comprehensive compound assignment test */

int main() {
    // Basic compound assignments
    int x = 100;
    x += 50;   // x = 150
    x -= 30;   // x = 120
    x *= 2;    // x = 240
    x /= 3;    // x = 80
    
    // Compound assignments with arrays
    int arr[2];
    arr[0] = 10;
    arr[1] = 20;
    
    arr[0] += arr[1];  // arr[0] = 30
    arr[1] *= 3;       // arr[1] = 60
    
    // Compound assignment with expression
    int result = 0;
    result += x + arr[0] + arr[1];  // 0 + 80 + 30 + 60 = 170
    
    return result;
}
