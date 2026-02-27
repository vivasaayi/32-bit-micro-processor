/*
 * Interactive CLI Demo for Custom RISC Processor
 * Demonstrates CLI functionality with command processing
 */

// Display controller addresses
#define DISPLAY_CTRL_BASE   0xFF000000
#define DISPLAY_TEXT_BASE   0xFF001000
#define DISPLAY_GFX_BASE    0xFF002000

// Control registers
#define MODE_REG     (DISPLAY_CTRL_BASE + 0x00)
#define CURSOR_X     (DISPLAY_CTRL_BASE + 0x04)
#define CURSOR_Y     (DISPLAY_CTRL_BASE + 0x08)
#define TEXT_COLOR   (DISPLAY_CTRL_BASE + 0x0C)

// Display modes
#define MODE_TEXT     0
#define MODE_GRAPHICS 1

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

// CLI state
typedef struct {
    int cursor_x;
    int cursor_y;
    int fg_color;
    int bg_color;
} cli_state_t;

static cli_state_t cli;

// Memory access functions
void write_reg(unsigned int addr, unsigned int val) {
    *((volatile unsigned int*)addr) = val;
}

unsigned int read_reg(unsigned int addr) {
    return *((volatile unsigned int*)addr);
}

// Basic CLI functions
void cli_init() {
    // Set text mode
    write_reg(MODE_REG, MODE_TEXT);
    
    // Initialize CLI state
    cli.cursor_x = 0;
    cli.cursor_y = 0;
    cli.fg_color = COLOR_WHITE;
    cli.bg_color = COLOR_BLACK;
    
    // Set cursor and color
    write_reg(CURSOR_X, cli.cursor_x);
    write_reg(CURSOR_Y, cli.cursor_y);
    write_reg(TEXT_COLOR, (cli.bg_color << 4) | cli.fg_color);
}

void cli_putchar(char c) {
    volatile unsigned short* text_buffer = (volatile unsigned short*)DISPLAY_TEXT_BASE;
    
    if (c == '\n') {
        cli.cursor_x = 0;
        cli.cursor_y++;
        if (cli.cursor_y >= 25) {
            cli.cursor_y = 24;
            // TODO: Implement scrolling
        }
    } else {
        int pos = cli.cursor_y * 80 + cli.cursor_x;
        unsigned short color_attr = (cli.bg_color << 4) | cli.fg_color;
        text_buffer[pos] = c | (color_attr << 8);
        
        cli.cursor_x++;
        if (cli.cursor_x >= 80) {
            cli.cursor_x = 0;
            cli.cursor_y++;
            if (cli.cursor_y >= 25) {
                cli.cursor_y = 24;
                // TODO: Implement scrolling
            }
        }
    }
    
    // Update hardware cursor
    write_reg(CURSOR_X, cli.cursor_x);
    write_reg(CURSOR_Y, cli.cursor_y);
}

void cli_puts(const char* str) {
    while (*str) {
        cli_putchar(*str);
        str++;
    }
}

void cli_set_color(int fg, int bg) {
    cli.fg_color = fg;
    cli.bg_color = bg;
    write_reg(TEXT_COLOR, (bg << 4) | fg);
}

void cli_clear_screen() {
    volatile unsigned short* text_buffer = (volatile unsigned short*)DISPLAY_TEXT_BASE;
    unsigned short blank = ' ' | ((cli.bg_color << 4 | cli.fg_color) << 8);
    
    for (int i = 0; i < 80 * 25; i++) {
        text_buffer[i] = blank;
    }
    
    cli.cursor_x = 0;
    cli.cursor_y = 0;
    write_reg(CURSOR_X, 0);
    write_reg(CURSOR_Y, 0);
}

// Demo functions
void demo_colors() {
    cli_puts("Color Test:\n");
    
    const char* color_names[] = {
        "BLACK", "BLUE", "GREEN", "CYAN", "RED", "MAGENTA", "BROWN", "WHITE",
        "GRAY", "LTBLUE", "LTGREEN", "LTCYAN", "LTRED", "LTMAGENTA", "YELLOW", "BRIGHT_WHITE"
    };
    
    for (int i = 0; i < 16; i++) {
        cli_set_color(i, COLOR_BLACK);
        cli_puts(color_names[i]);
        cli_puts(" ");
    }
    cli_puts("\n");
    cli_set_color(COLOR_WHITE, COLOR_BLACK);
}

void demo_graphics() {
    cli_puts("Switching to graphics mode...\n");
    
    // Brief delay
    for (int i = 0; i < 100000; i++) {
        // Delay
    }
    
    // Switch to graphics mode
    write_reg(MODE_REG, MODE_GRAPHICS);
    
    volatile unsigned char* framebuffer = (volatile unsigned char*)DISPLAY_GFX_BASE;
    
    // Clear screen to blue
    for (int i = 0; i < 640 * 480; i++) {
        framebuffer[i] = COLOR_BLUE;
    }
    
    // Draw a colorful pattern
    for (int y = 50; y < 430; y++) {
        for (int x = 50; x < 590; x++) {
            int pixel = y * 640 + x;
            framebuffer[pixel] = ((x + y) / 8) % 256;
        }
    }
    
    // Draw border
    for (int x = 0; x < 640; x++) {
        framebuffer[x] = COLOR_WHITE;                    // Top
        framebuffer[479 * 640 + x] = COLOR_WHITE;       // Bottom
    }
    for (int y = 0; y < 480; y++) {
        framebuffer[y * 640] = COLOR_WHITE;              // Left
        framebuffer[y * 640 + 639] = COLOR_WHITE;        // Right
    }
    
    // Wait in graphics mode
    for (int i = 0; i < 1000000; i++) {
        // Display graphics
    }
    
    // Switch back to text mode
    write_reg(MODE_REG, MODE_TEXT);
    cli_puts("Back to text mode!\n");
}

int main() {
    // Initialize CLI
    cli_init();
    
    // Clear screen and show welcome message
    cli_clear_screen();
    
    cli_set_color(COLOR_YELLOW, COLOR_BLUE);
    cli_puts("=== RISC Processor Display System ===\n");
    
    cli_set_color(COLOR_WHITE, COLOR_BLACK);
    cli_puts("Interactive CLI Demo\n\n");
    
    // Demonstrate text features
    cli_set_color(COLOR_GREEN, COLOR_BLACK);
    cli_puts("1. Text Mode Features:\n");
    cli_set_color(COLOR_WHITE, COLOR_BLACK);
    
    demo_colors();
    cli_puts("\n");
    
    // Demonstrate graphics
    cli_set_color(COLOR_CYAN, COLOR_BLACK);
    cli_puts("2. Graphics Mode Demo:\n");
    cli_set_color(COLOR_WHITE, COLOR_BLACK);
    
    demo_graphics();
    
    // Show completion message
    cli_set_color(COLOR_LTGREEN, COLOR_BLACK);
    cli_puts("Display system demo complete!\n");
    
    cli_set_color(COLOR_YELLOW, COLOR_BLACK);
    cli_puts("Features demonstrated:\n");
    cli_set_color(COLOR_WHITE, COLOR_BLACK);
    cli_puts("- Text mode with colors\n");
    cli_puts("- Graphics mode with pixels\n");
    cli_puts("- Mode switching\n");
    cli_puts("- CLI framework\n");
    
    // Keep the display active
    while (1) {
        for (int i = 0; i < 100000; i++) {
            // Keep system running
        }
    }
    
    return 0;
}
