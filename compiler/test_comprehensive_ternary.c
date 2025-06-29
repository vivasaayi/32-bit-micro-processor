/* Comprehensive ternary operator test */

int main() {
    // Basic ternary
    int a = 10;
    int b = 5;
    int max = (a > b) ? a : b;
    
    // Ternary with arithmetic
    int result = (max > 8) ? max * 2 : max + 3;
    
    // Ternary with array
    int arr[2];
    arr[0] = result;
    arr[1] = max;
    int final = (arr[0] > arr[1]) ? arr[0] : arr[1];
    
    return final;
}
