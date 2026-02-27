// 101_simple_framebuffer.c - Simple framebuffer test
// Basic test to write a few pixels to the framebuffer

#define FB_BASE_ADDR 0x10000  // 65536

int main() {
    log_string("=== Simple Framebuffer Test ===\n");
    
    // Get pointer to framebuffer
    unsigned int *framebuffer = (unsigned int*)FB_BASE_ADDR;
    
    log_string("Writing test pixels to framebuffer\n");
    
    // Write a few colored pixels
    framebuffer[0] = 0xFF0000FF;      // Red pixel at (0,0)
    framebuffer[1] = 0x00FF00FF;      // Green pixel at (1,0)
    framebuffer[2] = 0x0000FFFF;      // Blue pixel at (2,0)
    framebuffer[320] = 0xFFFF00FF;    // Yellow pixel at (0,1)
    framebuffer[321] = 0xFF00FFFF;    // Magenta pixel at (1,1)
    framebuffer[322] = 0x00FFFFFF;    // Cyan pixel at (2,1)
    
    // Write a small cross pattern in the center
    int center_x = 160;  // 320/2
    int center_y = 120;  // 240/2
    
    for (int i = -10; i <= 10; i++) {
        framebuffer[center_y * 320 + center_x + i] = 0xFFFFFFFF; // White horizontal line
        framebuffer[(center_y + i) * 320 + center_x] = 0xFFFFFFFF; // White vertical line
    }
    
    log_string("Simple framebuffer test completed\n");
    log_string("Check Java UI for white cross\n");
    
    return 1;  // Success
}
