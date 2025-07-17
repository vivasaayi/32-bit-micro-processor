/*
 * Simple CLI Library for Custom RISC Processor
 * Provides text-based command line interface functionality
 */

#ifndef CLI_H
#define CLI_H

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

// Colors (4-bit palette indices)
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
    char input_buffer[256];
    int input_pos;
} cli_state_t;

// Global CLI state
static cli_state_t cli;

// Memory access macros
#define WRITE_REG(addr, val) (*((volatile unsigned int*)(addr)) = (val))
#define READ_REG(addr) (*((volatile unsigned int*)(addr)))

// Basic I/O functions
void cli_init(void);
void cli_clear_screen(void);
void cli_set_color(int fg, int bg);
void cli_set_cursor(int x, int y);
void cli_putchar(char c);
void cli_puts(const char* str);
void cli_printf(const char* format, ...);
void cli_scroll_up(void);
char cli_getchar(void);
void cli_gets(char* buffer, int max_len);
void cli_process_command(const char* cmd);

// Graphics functions
void gfx_init(void);
void gfx_set_pixel(int x, int y, int color);
void gfx_draw_line(int x1, int y1, int x2, int y2, int color);
void gfx_draw_rect(int x, int y, int width, int height, int color);
void gfx_fill_rect(int x, int y, int width, int height, int color);
void gfx_clear_screen(int color);

// Command processing
typedef struct {
    const char* name;
    void (*handler)(int argc, char** argv);
    const char* help;
} command_t;

// Built-in commands
void cmd_help(int argc, char** argv);
void cmd_clear(int argc, char** argv);
void cmd_echo(int argc, char** argv);
void cmd_color(int argc, char** argv);
void cmd_mode(int argc, char** argv);
void cmd_pixel(int argc, char** argv);
void cmd_line(int argc, char** argv);
void cmd_rect(int argc, char** argv);

#endif // CLI_H
