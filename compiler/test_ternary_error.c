int main() {
    int x = 5;
    char c = 'a';
    float f = 3.14;
    
    // This should cause a type error: incompatible types in ternary
    int result = (x > 0) ? c : f;
    
    return result;
}
