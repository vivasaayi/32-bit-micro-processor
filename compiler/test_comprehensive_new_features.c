// Comprehensive test of new compiler features
int main() {
    // Feature 1: Boolean data type and operations
    bool flag1 = true;
    bool flag2 = false;
    bool result = flag1 && flag2;
    
    // Feature 2: Additional compound operators  
    int x = 10;
    x %= 3;     // x = 1
    x &= 5;     // x = 1 & 5 = 1
    x |= 8;     // x = 1 | 8 = 9
    x ^= 3;     // x = 9 ^ 3 = 10
    
    // Feature 3: Shift assignments
    int y = 4;
    y <<= 2;    // y = 4 << 2 = 16
    y >>= 1;    // y = 16 >> 1 = 8
    
    // Feature 5: Array initializer lists
    int numbers[4] = {1, 2, 3, 4};
    int sum = numbers[0] + numbers[1] + numbers[2] + numbers[3];
    
    // Ternary with boolean conditions
    int final_result = result ? sum : (x + y);
    
    return final_result;
}
