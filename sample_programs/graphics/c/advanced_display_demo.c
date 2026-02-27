/*
 * Advanced Display System Demo
 * Demonstrates CLI with simulated keyboard input and basic window management
 */

// Display system addresses  
#define DISPLAY_MODE_REG    0xFF000000
#define DISPLAY_CURSOR_X    0xFF000004
#define DISPLAY_CURSOR_Y    0xFF000008
#define DISPLAY_TEXT_COLOR  0xFF00000C
#define DISPLAY_TEXT_BASE   0xFF001000
#define DISPLAY_GFX_BASE    0xFF002000

// Display modes
#define MODE_TEXT     0
#define MODE_GRAPHICS 1
#define MODE_MIXED    2

// Color definitions
#define BLACK   0
#define BLUE    1
#define GREEN   2
#define CYAN    3
#define RED     4
#define MAGENTA 5
#define BROWN   6
#define WHITE   7
#define GRAY    8
#define LTBLUE  9
#define LTGREEN 10
#define LTCYAN  11
#define LTRED   12
#define LTMAGENTA 13
#define YELLOW  14
#define BRIGHT_WHITE 15

// Simple window structure
typedef struct {
    int x, y, width, height;
    int fg_color, bg_color;
    char title[32];
} window_t;

// CLI context
typedef struct {
    int cursor_x, cursor_y;
    int fg_color, bg_color;
    int mode;
} cli_context_t;

static cli_context_t cli;

// Memory access
void write_reg(unsigned int addr, unsigned int val) {
    *((volatile unsigned int*)addr) = val;
}

unsigned int read_reg(unsigned int addr) {
    return *((volatile unsigned int*)addr);
}

// Basic CLI functions
void cli_init() {
    cli.cursor_x = 0;
    cli.cursor_y = 0;
    cli.fg_color = WHITE;
    cli.bg_color = BLACK;
    cli.mode = MODE_TEXT;
    
    write_reg(DISPLAY_MODE_REG, MODE_TEXT);
    write_reg(DISPLAY_CURSOR_X, 0);
    write_reg(DISPLAY_CURSOR_Y, 0);
    write_reg(DISPLAY_TEXT_COLOR, (BLACK << 4) | WHITE);
}

void cli_set_cursor(int x, int y) {
    cli.cursor_x = x;
    cli.cursor_y = y;
    write_reg(DISPLAY_CURSOR_X, x);
    write_reg(DISPLAY_CURSOR_Y, y);
}

void cli_set_color(int fg, int bg) {
    cli.fg_color = fg;
    cli.bg_color = bg;
    write_reg(DISPLAY_TEXT_COLOR, (bg << 4) | fg);
}

void cli_putchar_at(int x, int y, char c, int fg, int bg) {
    volatile unsigned short* text_buffer = (volatile unsigned short*)DISPLAY_TEXT_BASE;
    int pos = y * 80 + x;
    unsigned short attr = (bg << 4) | fg;
    text_buffer[pos] = c | (attr << 8);
}

void cli_puts_at(int x, int y, const char* str, int fg, int bg) {
    int i = 0;
    while (str[i] && (x + i) < 80) {
        cli_putchar_at(x + i, y, str[i], fg, bg);
        i++;
    }
}

void cli_clear_region(int x, int y, int width, int height, int bg_color) {
    for (int row = y; row < y + height && row < 25; row++) {
        for (int col = x; col < x + width && col < 80; col++) {
            cli_putchar_at(col, row, ' ', WHITE, bg_color);
        }
    }
}

// Window management
void draw_window(window_t* win) {
    // Draw window background
    cli_clear_region(win->x, win->y, win->width, win->height, win->bg_color);
    
    // Draw title bar
    cli_clear_region(win->x, win->y, win->width, 1, BLUE);
    cli_puts_at(win->x + 1, win->y, win->title, BRIGHT_WHITE, BLUE);
    
    // Draw border (simplified)
    for (int i = 0; i < win->width; i++) {
        cli_putchar_at(win->x + i, win->y + win->height - 1, '-', win->fg_color, win->bg_color);
    }
    for (int i = 1; i < win->height - 1; i++) {
        cli_putchar_at(win->x, win->y + i, '|', win->fg_color, win->bg_color);
        cli_putchar_at(win->x + win->width - 1, win->y + i, '|', win->fg_color, win->bg_color);
    }
}

void window_puts(window_t* win, int rel_x, int rel_y, const char* str) {
    cli_puts_at(win->x + rel_x + 1, win->y + rel_y + 1, str, win->fg_color, win->bg_color);
}

// Graphics functions
void gfx_set_pixel(int x, int y, unsigned char color) {
    if (x >= 0 && x < 640 && y >= 0 && y < 480) {
        volatile unsigned char* framebuffer = (volatile unsigned char*)DISPLAY_GFX_BASE;
        framebuffer[y * 640 + x] = color;
    }
}

void gfx_draw_rect(int x, int y, int width, int height, unsigned char color) {
    for (int row = y; row < y + height; row++) {
        for (int col = x; col < x + width; col++) {
            gfx_set_pixel(col, row, color);
        }
    }
}

// Demo functions
void demo_text_windows() {
    cli_clear_region(0, 0, 80, 25, BLACK);
    
    // Main title
    cli_puts_at(25, 0, "Advanced Display System Demo", YELLOW, BLACK);
    cli_puts_at(30, 1, "Window Management", CYAN, BLACK);
    
    // Create multiple windows
    window_t win1 = {5, 3, 30, 8, WHITE, GRAY, "System Information"};
    window_t win2 = {40, 5, 35, 10, GREEN, BLACK, "Command Output"};
    window_t win3 = {10, 15, 25, 6, YELLOW, BLUE, "Status Monitor"};
    
    draw_window(&win1);
    draw_window(&win2);
    draw_window(&win3);
    
    // Add content to windows
    window_puts(&win1, 1, 1, "CPU: RISC-32");
    window_puts(&win1, 1, 2, "Memory: 64KB");
    window_puts(&win1, 1, 3, "Display: 640x480");
    window_puts(&win1, 1, 4, "Status: Running");
    
    window_puts(&win2, 1, 1, "> ls");
    window_puts(&win2, 1, 2, "display_demo.hex");
    window_puts(&win2, 1, 3, "system.v");
    window_puts(&win2, 1, 4, "> help");
    window_puts(&win2, 1, 5, "Available commands:");
    window_puts(&win2, 1, 6, "  clear, help, demo");
    
    window_puts(&win3, 1, 1, "Frames: 1234");
    window_puts(&win3, 1, 2, "Mode: Text");
    window_puts(&win3, 1, 3, "Active: Yes");
    
    // Status line
    cli_puts_at(0, 24, "Press any key to continue to graphics demo...", WHITE, BLACK);
}

void demo_graphics_mode() {
    write_reg(DISPLAY_MODE_REG, MODE_GRAPHICS);
    
    volatile unsigned char* fb = (volatile unsigned char*)DISPLAY_GFX_BASE;
    
    // Clear to dark blue
    for (int i = 0; i < 640 * 480; i++) {
        fb[i] = 1; // Blue
    }
    
    // Draw gradient background
    for (int y = 0; y < 480; y++) {
        for (int x = 0; x < 640; x++) {
            int color = ((x + y) / 8) % 16;
            gfx_set_pixel(x, y, color);
        }
    }
    
    // Draw some geometric shapes
    gfx_draw_rect(50, 50, 100, 80, RED);
    gfx_draw_rect(200, 100, 150, 120, GREEN);
    gfx_draw_rect(400, 80, 120, 100, YELLOW);
    
    // Draw "pixels" pattern
    for (int y = 300; y < 400; y += 4) {
        for (int x = 100; x < 500; x += 4) {
            gfx_draw_rect(x, y, 2, 2, BRIGHT_WHITE);
        }
    }
    
    // Border
    for (int x = 0; x < 640; x++) {
        gfx_set_pixel(x, 0, WHITE);
        gfx_set_pixel(x, 479, WHITE);
    }
    for (int y = 0; y < 480; y++) {
        gfx_set_pixel(0, y, WHITE);
        gfx_set_pixel(639, y, WHITE);
    }
}

void demo_mixed_mode() {
    write_reg(DISPLAY_MODE_REG, MODE_MIXED);
    
    // Graphics background stays the same
    // Add text overlay
    cli_clear_region(60, 5, 20, 5, BLACK);
    cli_puts_at(61, 6, "MIXED MODE ACTIVE", BRIGHT_WHITE, BLACK);
    cli_puts_at(61, 7, "Text over graphics", YELLOW, BLACK);
}

// Simulated keyboard input for demo
char simulated_input[] = "help\nclear\ndemo\ngraphics\nmixed\nexit\n";
int input_pos = 0;

char get_simulated_key() {
    if (input_pos < sizeof(simulated_input) - 1) {
        return simulated_input[input_pos++];
    }
    return 0;
}

int main() {
    cli_init();
    
    // Demo sequence
    demo_text_windows();
    
    // Simulate waiting for input
    for (int i = 0; i < 500000; i++) {
        // Delay
    }
    
    demo_graphics_mode();
    
    // Wait in graphics mode
    for (int i = 0; i < 800000; i++) {
        // Display graphics
    }
    
    demo_mixed_mode();
    
    // Wait in mixed mode
    for (int i = 0; i < 600000; i++) {
        // Display mixed mode
    }
    
    // Back to text mode for conclusion
    write_reg(DISPLAY_MODE_REG, MODE_TEXT);
    cli_clear_region(0, 0, 80, 25, BLACK);
    
    cli_puts_at(20, 10, "ADVANCED DISPLAY DEMO COMPLETE", BRIGHT_WHITE, BLACK);
    cli_puts_at(25, 12, "Features Demonstrated:", YELLOW, BLACK);
    cli_puts_at(5, 14, "✓ Text mode with colors and cursor control", GREEN, BLACK);
    cli_puts_at(5, 15, "✓ Window management and borders", GREEN, BLACK);
    cli_puts_at(5, 16, "✓ Graphics mode with pixel control", GREEN, BLACK);
    cli_puts_at(5, 17, "✓ Mixed mode (text over graphics)", GREEN, BLACK);
    cli_puts_at(5, 18, "✓ Memory-mapped I/O interface", GREEN, BLACK);
    
    cli_puts_at(15, 22, "System ready for interactive use!", CYAN, BLACK);
    
    // Keep running
    while (1) {
        for (int i = 0; i < 100000; i++) {
            // Keep system active
        }
    }
    
    return 0;
}
