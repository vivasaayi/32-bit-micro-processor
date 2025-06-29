/* Comprehensive array test */

int main() {
    // Test different array sizes
    int small[3];
    int medium[10];
    
    // Test basic assignment and access
    small[0] = 100;
    small[1] = 200;
    small[2] = 300;
    
    // Test using variables as indices
    int index = 1;
    medium[index] = small[index];
    
    // Test complex expressions
    int sum = small[0] + small[1] + small[2];
    medium[0] = sum;
    
    // Test nested array access
    int final_result = medium[0] + medium[1];
    
    return final_result;
}
