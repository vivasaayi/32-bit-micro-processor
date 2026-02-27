// 100_framebuffer_graphics.c - Framebuffer graphics test
// Tests direct framebuffer access with various patterns

// Framebuffer configuration
#define FB_BASE_ADDR 0x8000
#define FB_WIDTH 320
#define FB_HEIGHT 240
#define FB_PIXELS (FB_WIDTH * FB_HEIGHT)

// Color definitions (32-bit RGBA format: 0xRRGGBBAA)
#define COLOR_BLACK   0x000000FF
#define COLOR_WHITE   0xFFFFFFFF
#define COLOR_RED     0xFF0000FF
#define COLOR_GREEN   0x00FF00FF
#define COLOR_BLUE    0x0000FFFF
#define COLOR_YELLOW  0xFFFF00FF
#define COLOR_CYAN    0x00FFFFFF
#define COLOR_MAGENTA 0xFF00FFFF

// Function to set a pixel at coordinates (x, y) with given color
void set_pixel(int x, int y, unsigned int color) {
    if (x >= 0 && x < FB_WIDTH && y >= 0 && y < FB_HEIGHT) {
        unsigned int *framebuffer = (unsigned int*)FB_BASE_ADDR;
        framebuffer[y * FB_WIDTH + x] = color;
    }
}

// Function to fill entire screen with a color
void fill_screen(unsigned int color) {
    unsigned int *framebuffer = (unsigned int*)FB_BASE_ADDR;
    for (int i = 0; i < FB_PIXELS; i++) {
        framebuffer[i] = color;
    }
}

// Function to draw a horizontal line
void draw_hline(int x0, int x1, int y, unsigned int color) {
    if (x0 > x1) {
        int temp = x0;
        x0 = x1;
        x1 = temp;
    }
    for (int x = x0; x <= x1; x++) {
        set_pixel(x, y, color);
    }
}

// Function to draw a vertical line
void draw_vline(int x, int y0, int y1, unsigned int color) {
    if (y0 > y1) {
        int temp = y0;
        y0 = y1;
        y1 = temp;
    }
    for (int y = y0; y <= y1; y++) {
        set_pixel(x, y, color);
    }
}

// Function to draw a rectangle
void draw_rectangle(int x0, int y0, int x1, int y1, unsigned int color) {
    draw_hline(x0, x1, y0, color);  // Top edge
    draw_hline(x0, x1, y1, color);  // Bottom edge
    draw_vline(x0, y0, y1, color);  // Left edge
    draw_vline(x1, y0, y1, color);  // Right edge
}

// Function to fill a rectangle
void fill_rectangle(int x0, int y0, int x1, int y1, unsigned int color) {
    if (x0 > x1) {
        int temp = x0;
        x0 = x1;
        x1 = temp;
    }
    if (y0 > y1) {
        int temp = y0;
        y0 = y1;
        y1 = temp;
    }
    
    for (int y = y0; y <= y1; y++) {
        for (int x = x0; x <= x1; x++) {
            set_pixel(x, y, color);
        }
    }
}

// Function to create a gradient pattern
void draw_gradient() {
    for (int y = 0; y < FB_HEIGHT; y++) {
        for (int x = 0; x < FB_WIDTH; x++) {
            unsigned int r = (x * 255) / FB_WIDTH;
            unsigned int g = (y * 255) / FB_HEIGHT;
            unsigned int b = 128;
            unsigned int color = (r << 24) | (g << 16) | (b << 8) | 0xFF;
            set_pixel(x, y, color);
        }
    }
}

// Function to draw a test pattern
void draw_test_pattern() {
    // Clear screen to black
    fill_screen(COLOR_BLACK);
    
    // Draw colored squares in corners
    fill_rectangle(0, 0, 50, 50, COLOR_RED);           // Top-left: Red
    fill_rectangle(FB_WIDTH-51, 0, FB_WIDTH-1, 50, COLOR_GREEN);  // Top-right: Green
    fill_rectangle(0, FB_HEIGHT-51, 50, FB_HEIGHT-1, COLOR_BLUE); // Bottom-left: Blue
    fill_rectangle(FB_WIDTH-51, FB_HEIGHT-51, FB_WIDTH-1, FB_HEIGHT-1, COLOR_WHITE); // Bottom-right: White
    
    // Draw center cross
    draw_hline(FB_WIDTH/4, 3*FB_WIDTH/4, FB_HEIGHT/2, COLOR_YELLOW);
    draw_vline(FB_WIDTH/2, FB_HEIGHT/4, 3*FB_HEIGHT/4, COLOR_CYAN);
    
    // Draw border
    draw_rectangle(10, 10, FB_WIDTH-11, FB_HEIGHT-11, COLOR_MAGENTA);
}

// Simple delay function
void delay(int cycles) {
    for (int i = 0; i < cycles; i++) {
        // Simple delay loop
        int dummy = i * 2;
    }
}

int main() {
    //log_string("=== Framebuffer Graphics Test ===\n");
    // log_string("Testing direct framebuffer access\n");
    
    // Test 1: Fill screen with solid colors
    // log_string("Test 1: Solid colors\n");
    fill_screen(COLOR_RED);
    delay(10000);
    
    fill_screen(COLOR_GREEN);
    delay(10000);
    
    fill_screen(COLOR_BLUE);
    delay(10000);
    
    // Test 2: Draw gradient
    // log_string("Test 2: Gradient pattern\n");
    draw_gradient();
    delay(20000);
    
    // Test 3: Test pattern with shapes
    // log_string("Test 3: Test pattern\n");
    draw_test_pattern();
    delay(30000);
    
    // Test 4: Animation - moving rectangle
    // log_string("Test 4: Animation\n");
    for (int frame = 0; frame < 50; frame++) {
        fill_screen(COLOR_BLACK);
        
        int x = (frame * 4) % (FB_WIDTH - 40);
        int y = (frame * 2) % (FB_HEIGHT - 30);
        
        fill_rectangle(x, y, x + 40, y + 30, COLOR_YELLOW);
        delay(5000);
    }
    
    // Test 5: Final colorful pattern
    // log_string("Test 5: Final pattern\n");
    for (int y = 0; y < FB_HEIGHT; y += 4) {
        for (int x = 0; x < FB_WIDTH; x += 4) {
            unsigned int color = ((x * 255 / FB_WIDTH) << 24) | 
                               ((y * 255 / FB_HEIGHT) << 16) | 
                               (((x + y) * 127 / (FB_WIDTH + FB_HEIGHT)) << 8) | 0xFF;
            fill_rectangle(x, y, x + 3, y + 3, color);
        }
    }
    
    // log_string("Framebuffer graphics test completed!\n");
    // log_string("Check Java UI for visual output\n");
    
    return 0;
}
