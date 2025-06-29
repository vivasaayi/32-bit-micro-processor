int main() {
    int x = 5;
    
    // This should cause a type error: string is not numeric for condition
    int result = ("hello" > 0) ? x : 10;
    
    return result;
}
