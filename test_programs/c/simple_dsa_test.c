// Simple test without complex syntax
int main() {
    int x = 10;
    int y = 20;
    int z = x + y;
    
    // Write result to status location
    // Avoid cast syntax by using direct assignment
    int status_addr = 0x2000;
    int *status_ptr = &status_addr;
    
    if (z == 30) {
        *status_ptr = 1;
    } else {
        *status_ptr = 0;
    }
    
    return 0;
}
