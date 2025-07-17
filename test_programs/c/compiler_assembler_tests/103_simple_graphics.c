// 103_simple_graphics.c - Very simple graphics test
// Basic framebuffer access test with minimal complexity

int main() {
    log_string("=== Simple Graphics Test ===\n");
    
    // Direct framebuffer access - start simple
    unsigned int *fb = (unsigned int*)0x800;  // Framebuffer base address (2048)
    // unsigned int *fb = (unsigned int*)0x4000;  // Framebuffer base address (16384)

    log_string("Setting first pixel to red\n");
    fb[0] = 0xFF0000FF;  // Red pixel at (0,0)
    
    log_string("Setting pixel at (1,0) to green\n");
    fb[1] = 0x00FF00FF;  // Green pixel at (1,0)
    
    log_string("Setting pixel at (0,1) to blue\n"); 
    fb[320] = 0x0000FFFF;  // Blue pixel at (0,1) - next row
    
    log_string("Filling first 100 pixels with white\n");
    for (int i = 0; i < 100; i++) {
        fb[i] = 0xFFFFFFFF;  // White pixels
    }
    
    log_string("Creating red square (10x10)\n");
    for (int y = 10; y < 20; y++) {
        for (int x = 10; x < 20; x++) {
            fb[y * 320 + x] = 0xFF0000FF;  // Red square
        }
    }
    
    log_string("Creating green line across screen\n");
    for (int x = 0; x < 320; x++) {
        fb[50 * 320 + x] = 0x00FF00FF;  // Green horizontal line at y=50
    }
    
    log_string("Simple graphics test completed\n");
    log_string("Check framebuffer output\n");
    
    return 0;
}
