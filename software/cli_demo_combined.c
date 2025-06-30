/*
 * Combined CLI Demo Program
 * All code in one file for simple compilation
 */

// Memory access macros
#define WRITE_REG(addr, val) (*((volatile unsigned int*)(addr)) = (val))
#define READ_REG(addr) (*((volatile unsigned int*)(addr)))

// Display controller memory map
#define DISPLAY_CTRL_BASE   0xFF000000
#define DISPLAY_TEXT_BASE   0xFF001000
#define DISPLAY_GFX_BASE    0xFF002000
#define DISPLAY_PAL_BASE    0xFF050000

// Control registers
#define MODE_REG     (DISPLAY_CTRL_BASE + 0x00)
#define CURSOR_X     (DISPLAY_CTRL_BASE + 0x04)
#define CURSOR_Y     (DISPLAY_CTRL_BASE + 0x08)
#define TEXT_COLOR   (DISPLAY_CTRL_BASE + 0x0C)
#define GRAPHICS_X   (DISPLAY_CTRL_BASE + 0x10)
#define GRAPHICS_Y   (DISPLAY_CTRL_BASE + 0x14)
#define PIXEL_COLOR  (DISPLAY_CTRL_BASE + 0x18)
#define STATUS_REG   (DISPLAY_CTRL_BASE + 0x1C)

// Display modes
#define MODE_TEXT     0
#define MODE_GRAPHICS 1
#define MODE_MIXED    2

// Text dimensions
#define TEXT_COLS 80
#define TEXT_ROWS 25

// Colors
#define COLOR_BLACK   0
#define COLOR_BLUE    1
#define COLOR_GREEN   2
#define COLOR_CYAN    3
#define COLOR_RED     4
#define COLOR_MAGENTA 5
#define COLOR_BROWN   6
#define COLOR_WHITE   7
#define COLOR_GRAY    8
#define COLOR_LTBLUE  9
#define COLOR_LTGREEN 10
#define COLOR_LTCYAN  11
#define COLOR_LTRED   12
#define COLOR_LTMAGENTA 13
#define COLOR_YELLOW  14
#define COLOR_BRIGHT_WHITE 15

// Global state
struct {
    int cursor_x;
    int cursor_y;
    int fg_color;
    int bg_color;
} cli;

// Function prototypes
void cli_init(void);
void cli_clear_screen(void);
void cli_set_color(int fg, int bg);
void cli_set_cursor(int x, int y);
void cli_putchar(char c);
void cli_puts(const char* str);
void cli_scroll_up(void);
void gfx_init(void);
void gfx_set_pixel(int x, int y, int color);
void gfx_draw_line(int x1, int y1, int x2, int y2, int color);
void gfx_draw_rect(int x, int y, int width, int height, int color);
void gfx_fill_rect(int x, int y, int width, int height, int color);
void gfx_clear_screen(int color);

// CLI Functions
void cli_init(void) {
    WRITE_REG(MODE_REG, MODE_TEXT);
    cli.cursor_x = 0;
    cli.cursor_y = 0;
    cli.fg_color = COLOR_WHITE;
    cli.bg_color = COLOR_BLACK;
    cli_set_color(COLOR_WHITE, COLOR_BLACK);
    cli_clear_screen();
}

void cli_clear_screen(void) {
    volatile unsigned short* text_buf = (volatile unsigned short*)DISPLAY_TEXT_BASE;
    unsigned short clear_char = 0x0720;
    
    for (int i = 0; i < TEXT_COLS * TEXT_ROWS; i++) {
        text_buf[i] = clear_char;
    }
    
    cli.cursor_x = 0;
    cli.cursor_y = 0;
    cli_set_cursor(0, 0);
}

void cli_set_color(int fg, int bg) {
    cli.fg_color = fg;
    cli.bg_color = bg;
    unsigned char color = (bg << 4) | fg;
    WRITE_REG(TEXT_COLOR, color);
}

void cli_set_cursor(int x, int y) {
    if (x >= 0 && x < TEXT_COLS && y >= 0 && y < TEXT_ROWS) {
        cli.cursor_x = x;
        cli.cursor_y = y;
        WRITE_REG(CURSOR_X, x);
        WRITE_REG(CURSOR_Y, y);
    }
}

void cli_putchar(char c) {
    if (c == '\n') {
        cli.cursor_x = 0;
        cli.cursor_y++;
        if (cli.cursor_y >= TEXT_ROWS) {
            cli_scroll_up();
            cli.cursor_y = TEXT_ROWS - 1;
        }
        cli_set_cursor(cli.cursor_x, cli.cursor_y);
    } else {
        volatile unsigned short* text_buf = (volatile unsigned short*)DISPLAY_TEXT_BASE;
        int pos = cli.cursor_y * TEXT_COLS + cli.cursor_x;
        unsigned char attr = (cli.bg_color << 4) | cli.fg_color;
        text_buf[pos] = (attr << 8) | c;
        
        cli.cursor_x++;
        if (cli.cursor_x >= TEXT_COLS) {
            cli.cursor_x = 0;
            cli.cursor_y++;
            if (cli.cursor_y >= TEXT_ROWS) {
                cli_scroll_up();
                cli.cursor_y = TEXT_ROWS - 1;
            }
        }
        cli_set_cursor(cli.cursor_x, cli.cursor_y);
    }
}

void cli_puts(const char* str) {
    while (*str) {
        cli_putchar(*str++);
    }
}

void cli_scroll_up(void) {
    volatile unsigned short* text_buf = (volatile unsigned short*)DISPLAY_TEXT_BASE;
    
    for (int y = 0; y < TEXT_ROWS - 1; y++) {
        for (int x = 0; x < TEXT_COLS; x++) {
            text_buf[y * TEXT_COLS + x] = text_buf[(y + 1) * TEXT_COLS + x];
        }
    }
    
    for (int x = 0; x < TEXT_COLS; x++) {
        text_buf[(TEXT_ROWS - 1) * TEXT_COLS + x] = 0x0720;
    }
}

// Graphics Functions
void gfx_init(void) {
    WRITE_REG(MODE_REG, MODE_GRAPHICS);
}

void gfx_set_pixel(int x, int y, int color) {
    if (x >= 0 && x < 640 && y >= 0 && y < 480) {
        volatile unsigned char* fb = (volatile unsigned char*)DISPLAY_GFX_BASE;
        fb[y * 640 + x] = color;
    }
}

void gfx_clear_screen(int color) {
    volatile unsigned char* fb = (volatile unsigned char*)DISPLAY_GFX_BASE;
    for (int i = 0; i < 640 * 480; i++) {
        fb[i] = color;
    }
}

void gfx_draw_line(int x1, int y1, int x2, int y2, int color) {
    int dx = x2 - x1;
    int dy = y2 - y1;
    int dx_abs = (dx < 0) ? -dx : dx;
    int dy_abs = (dy < 0) ? -dy : dy;
    int x_inc = (dx < 0) ? -1 : 1;
    int y_inc = (dy < 0) ? -1 : 1;
    int error = dx_abs - dy_abs;
    
    int x = x1, y = y1;
    
    while (1) {
        gfx_set_pixel(x, y, color);
        
        if (x == x2 && y == y2) break;
        
        int error2 = 2 * error;
        if (error2 > -dy_abs) {
            error -= dy_abs;
            x += x_inc;
        }
        if (error2 < dx_abs) {
            error += dx_abs;
            y += y_inc;
        }
    }
}

void gfx_draw_rect(int x, int y, int width, int height, int color) {
    gfx_draw_line(x, y, x + width - 1, y, color);
    gfx_draw_line(x, y + height - 1, x + width - 1, y + height - 1, color);
    gfx_draw_line(x, y, x, y + height - 1, color);
    gfx_draw_line(x + width - 1, y, x + width - 1, y + height - 1, color);
}

void gfx_fill_rect(int x, int y, int width, int height, int color) {
    for (int dy = 0; dy < height; dy++) {
        for (int dx = 0; dx < width; dx++) {
            gfx_set_pixel(x + dx, y + dy, color);
        }
    }
}

// Main program
int main() {
    cli_init();
    
    cli_puts("=== Display System Demo ===\n\n");
    
    cli_puts("1. Text Mode Features:\n");
    
    cli_set_color(COLOR_YELLOW, COLOR_BLUE);
    cli_puts("   * Colored text support\n");
    
    cli_set_color(COLOR_GREEN, COLOR_BLACK);
    cli_puts("   * Multiple colors available\n");
    
    cli_set_color(COLOR_WHITE, COLOR_BLACK);
    cli_puts("   * Easy color switching\n\n");
    
    cli_puts("2. Cursor Control:\n");
    cli_set_cursor(10, cli.cursor_y);
    cli_puts("This text is indented!\n");
    
    cli_set_cursor(0, cli.cursor_y);
    cli_puts("   Back to normal position\n\n");
    
    cli_puts("3. Switching to Graphics Mode...\n");
    
    // Simple delay
    for (int i = 0; i < 100000; i++) {
        // Delay loop
    }
    
    gfx_init();
    gfx_clear_screen(COLOR_BLUE);
    
    // Draw graphics
    gfx_draw_rect(10, 10, 620, 460, COLOR_WHITE);
    gfx_fill_rect(50, 50, 100, 80, COLOR_RED);
    gfx_fill_rect(200, 50, 100, 80, COLOR_GREEN);
    gfx_fill_rect(350, 50, 100, 80, COLOR_YELLOW);
    
    gfx_draw_line(50, 200, 550, 200, COLOR_WHITE);
    gfx_draw_line(50, 250, 550, 350, COLOR_LTGREEN);
    gfx_draw_line(550, 250, 50, 350, COLOR_LTRED);
    
    for (int i = 0; i < 50; i++) {
        gfx_set_pixel(100 + i, 400 + (i % 10), COLOR_BRIGHT_WHITE);
        gfx_set_pixel(100 + i, 410 + (i % 15), COLOR_LTCYAN);
    }
    
    // Wait in graphics mode
    for (int i = 0; i < 500000; i++) {
        // Delay
    }
    
    // Switch to mixed mode
    WRITE_REG(MODE_REG, MODE_MIXED);
    
    cli_set_cursor(0, 20);
    cli_set_color(COLOR_BRIGHT_WHITE, COLOR_BLACK);
    cli_puts("Mixed Mode: Graphics + Text Overlay");
    
    cli_set_cursor(0, 21);
    cli_puts("Text appears over graphics background");
    
    cli_set_cursor(0, 23);
    cli_puts("CLI Demo Complete!");
    
    return 0;
}
