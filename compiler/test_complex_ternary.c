int main() {
    int x = 15;
    int y = 20;
    int z = 10;
    
    // Nested ternary: find minimum of three numbers
    int min = (x < y) ? ((x < z) ? x : z) : ((y < z) ? y : z);
    
    // Simple ternary with arithmetic
    int result = (min > 10) ? min * 2 : min + 5;
    
    return result;
}
