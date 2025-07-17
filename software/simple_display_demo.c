/*
 * Simple Display Demo for Custom RISC Processor
 * Basic demonstration of display functionality
 */

// Memory access macros - simplify for our compiler
#define DISPLAY_MODE     0xFF000000
#define DISPLAY_CURSOR_X 0xFF000004
#define DISPLAY_CURSOR_Y 0xFF000008
#define DISPLAY_COLOR    0xFF00000C
#define TEXT_BUFFER      0xFF001000
#define GRAPHICS_BUFFER  0xFF002000

// Colors
#define BLACK   0
#define BLUE    1
#define GREEN   2
#define RED     4
#define YELLOW  14
#define WHITE   15

// Simple memory write function
void write_display_reg(int addr, int value) {
    volatile int* reg = (volatile int*)addr;
    *reg = value;
}

// Simple text output function
void put_text_char(int x, int y, char c, int color) {
    volatile short* text = (volatile short*)TEXT_BUFFER;
    int pos = y * 80 + x;
    text[pos] = (color << 8) | c;
}

// Simple graphics pixel function
void put_pixel(int x, int y, int color) {
    volatile char* graphics = (volatile char*)GRAPHICS_BUFFER;
    if (x >= 0 && x < 640 && y >= 0 && y < 480) {
        graphics[y * 640 + x] = color;
    }
}

int main() {
    int i;
    int x, y;
    
    // Set text mode
    write_display_reg(DISPLAY_MODE, 0);
    
    // Clear screen by writing spaces
    for (i = 0; i < 2000; i++) {
        volatile short* text = (volatile short*)TEXT_BUFFER;
        text[i] = 0x0720; // Space with default color
    }
    
    // Write "HELLO WORLD" in different colors
    put_text_char(10, 5, 'H', YELLOW);
    put_text_char(11, 5, 'E', YELLOW);
    put_text_char(12, 5, 'L', YELLOW);
    put_text_char(13, 5, 'L', YELLOW);
    put_text_char(14, 5, 'O', YELLOW);
    put_text_char(15, 5, ' ', WHITE);
    put_text_char(16, 5, 'W', GREEN);
    put_text_char(17, 5, 'O', GREEN);
    put_text_char(18, 5, 'R', GREEN);
    put_text_char(19, 5, 'L', GREEN);
    put_text_char(20, 5, 'D', GREEN);
    
    // Write "DISPLAY TEST" on another line
    put_text_char(10, 7, 'D', RED);
    put_text_char(11, 7, 'I', RED);
    put_text_char(12, 7, 'S', RED);
    put_text_char(13, 7, 'P', RED);
    put_text_char(14, 7, 'L', RED);
    put_text_char(15, 7, 'A', RED);
    put_text_char(16, 7, 'Y', RED);
    put_text_char(17, 7, ' ', WHITE);
    put_text_char(18, 7, 'T', BLUE);
    put_text_char(19, 7, 'E', BLUE);
    put_text_char(20, 7, 'S', BLUE);
    put_text_char(21, 7, 'T', BLUE);
    
    // Simple delay
    for (i = 0; i < 100000; i++) {
        // Delay loop
    }
    
    // Switch to graphics mode
    write_display_reg(DISPLAY_MODE, 1);
    
    // Clear graphics screen to blue
    for (i = 0; i < 640 * 480; i++) {
        volatile char* graphics = (volatile char*)GRAPHICS_BUFFER;
        graphics[i] = BLUE;
    }
    
    // Draw a simple pattern - horizontal lines
    for (y = 50; y < 100; y++) {
        for (x = 50; x < 500; x++) {
            put_pixel(x, y, RED);
        }
    }
    
    // Draw vertical lines
    for (x = 100; x < 150; x++) {
        for (y = 150; y < 400; y++) {
            put_pixel(x, y, GREEN);
        }
    }
    
    // Draw diagonal pattern
    for (i = 0; i < 200; i++) {
        put_pixel(200 + i, 200 + i, YELLOW);
        put_pixel(200 + i, 400 - i, WHITE);
    }
    
    // Simple delay in graphics mode
    for (i = 0; i < 500000; i++) {
        // Delay loop
    }
    
    // Switch to mixed mode
    write_display_reg(DISPLAY_MODE, 2);
    
    // Add text overlay
    put_text_char(5, 20, 'M', WHITE);
    put_text_char(6, 20, 'I', WHITE);
    put_text_char(7, 20, 'X', WHITE);
    put_text_char(8, 20, 'E', WHITE);
    put_text_char(9, 20, 'D', WHITE);
    put_text_char(10, 20, ' ', WHITE);
    put_text_char(11, 20, 'M', WHITE);
    put_text_char(12, 20, 'O', WHITE);
    put_text_char(13, 20, 'D', WHITE);
    put_text_char(14, 20, 'E', WHITE);
    
    put_text_char(5, 22, 'D', GREEN);
    put_text_char(6, 22, 'E', GREEN);
    put_text_char(7, 22, 'M', GREEN);
    put_text_char(8, 22, 'O', GREEN);
    put_text_char(9, 22, ' ', WHITE);
    put_text_char(10, 22, 'O', YELLOW);
    put_text_char(11, 22, 'K', YELLOW);
    
    return 0;
}
