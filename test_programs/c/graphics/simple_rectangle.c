/*
 * Simple Rectangle Drawing Test
 * 
 * This C program draws a yellow rectangle on the framebuffer
 * at address 0x800 (2048), which is where our assembly test worked.
 * 
 * Framebuffer layout: 320x240 pixels, 32-bit RGBA format
 * Yellow color: R=255, G=255, B=0, A=255 (0xFFFF00FF)
 */

// Framebuffer constants
#define FB_WIDTH 320
#define FB_HEIGHT 240
#define FB_BASE_ADDR 0x800  // 2048 - same as assembly test

// Colors (RGBA format)
#define COLOR_BLACK   0x000000FF
#define COLOR_YELLOW  0xFFFF00FF
#define COLOR_RED     0xFF0000FF
#define COLOR_GREEN   0x00FF00FF
#define COLOR_BLUE    0x0000FFFF

// Utility function to set a pixel
void set_pixel(int x, int y, unsigned int color) {
    if (x >= 0 && x < FB_WIDTH && y >= 0 && y < FB_HEIGHT) {
        unsigned int *fb = (unsigned int *)FB_BASE_ADDR;
        fb[y * FB_WIDTH + x] = color;
    }
}

// Draw a filled rectangle
void draw_rectangle(int x1, int y1, int x2, int y2, unsigned int color) {
    int x, y;
    for (y = y1; y <= y2; y++) {
        for (x = x1; x <= x2; x++) {
            set_pixel(x, y, color);
        }
    }
}

int main() {
    // Initialize variables
    int rect_x1 = 50;
    int rect_y1 = 40;
    int rect_x2 = 150;
    int rect_y2 = 120;
    
    // Clear framebuffer to black first (optional - testbench does this)
    draw_rectangle(0, 0, FB_WIDTH-1, FB_HEIGHT-1, COLOR_BLACK);
    
    // Draw yellow rectangle - same dimensions as assembly test
    draw_rectangle(rect_x1, rect_y1, rect_x2, rect_y2, COLOR_YELLOW);
    
    // Draw a small red border around it
    draw_rectangle(rect_x1-2, rect_y1-2, rect_x2+2, rect_y2+2, COLOR_RED);
    draw_rectangle(rect_x1-1, rect_y1-1, rect_x2+1, rect_y2+1, COLOR_BLACK);
    draw_rectangle(rect_x1, rect_y1, rect_x2, rect_y2, COLOR_YELLOW);
    
    // Return success
    return 42;  // Unique return value for verification
}
