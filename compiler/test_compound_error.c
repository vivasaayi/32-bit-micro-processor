int main() {
    int x = 10;
    char* str = "hello";
    
    // This should cause an error: can't do arithmetic on string
    x += str;
    
    return x;
}
