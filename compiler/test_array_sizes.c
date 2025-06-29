int main() {
    int small[2];
    int large[10];
    
    small[0] = 1;
    small[1] = 2;
    
    large[0] = small[0];
    large[9] = small[1];
    
    return large[0] + large[9];
}
