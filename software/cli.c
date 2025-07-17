/*
 * CLI Implementation for Custom RISC Processor
 */

#include "cli.h"

// Command table
static const command_t commands[] = {
    {"help",  cmd_help,  "Show available commands"},
    {"clear", cmd_clear, "Clear the screen"},
    {"echo",  cmd_echo,  "Echo text to screen"},
    {"color", cmd_color, "Set text color (fg bg)"},
    {"mode",  cmd_mode,  "Set display mode (0=text, 1=graphics, 2=mixed)"},
    {"pixel", cmd_pixel, "Set pixel (x y color)"},
    {"line",  cmd_line,  "Draw line (x1 y1 x2 y2 color)"},
    {"rect",  cmd_rect,  "Draw rectangle (x y w h color)"},
    {0, 0, 0} // End marker
};

// Initialize CLI
void cli_init(void) {
    // Set text mode
    WRITE_REG(MODE_REG, MODE_TEXT);
    
    // Initialize state
    cli.cursor_x = 0;
    cli.cursor_y = 0;
    cli.fg_color = COLOR_WHITE;
    cli.bg_color = COLOR_BLACK;
    cli.input_pos = 0;
    
    // Set initial color
    cli_set_color(COLOR_WHITE, COLOR_BLACK);
    
    // Clear screen
    cli_clear_screen();
    
    // Display welcome message
    cli_puts("Custom RISC Processor CLI v1.0\n");
    cli_puts("Type 'help' for available commands\n\n");
}

// Clear screen
void cli_clear_screen(void) {
    // Clear text buffer by writing spaces
    volatile unsigned short* text_buf = (volatile unsigned short*)DISPLAY_TEXT_BASE;
    unsigned short clear_char = 0x0720; // Space with default attributes
    
    for (int i = 0; i < TEXT_COLS * TEXT_ROWS; i++) {
        text_buf[i] = clear_char;
    }
    
    // Reset cursor
    cli.cursor_x = 0;
    cli.cursor_y = 0;
    cli_set_cursor(0, 0);
}

// Set text color
void cli_set_color(int fg, int bg) {
    cli.fg_color = fg & 0xF;
    cli.bg_color = bg & 0xF;
    unsigned char color = (bg << 4) | fg;
    WRITE_REG(TEXT_COLOR, color);
}

// Set cursor position
void cli_set_cursor(int x, int y) {
    if (x >= 0 && x < TEXT_COLS && y >= 0 && y < TEXT_ROWS) {
        cli.cursor_x = x;
        cli.cursor_y = y;
        WRITE_REG(CURSOR_X, x);
        WRITE_REG(CURSOR_Y, y);
    }
}

// Put character at current position
void cli_putchar(char c) {
    if (c == '\n') {
        // Newline
        cli.cursor_x = 0;
        cli.cursor_y++;
        if (cli.cursor_y >= TEXT_ROWS) {
            cli_scroll_up();
            cli.cursor_y = TEXT_ROWS - 1;
        }
        cli_set_cursor(cli.cursor_x, cli.cursor_y);
    } else if (c == '\r') {
        // Carriage return
        cli.cursor_x = 0;
        cli_set_cursor(cli.cursor_x, cli.cursor_y);
    } else if (c == '\b') {
        // Backspace
        if (cli.cursor_x > 0) {
            cli.cursor_x--;
            cli_set_cursor(cli.cursor_x, cli.cursor_y);
            // Write space to erase character
            volatile unsigned short* text_buf = (volatile unsigned short*)DISPLAY_TEXT_BASE;
            int pos = cli.cursor_y * TEXT_COLS + cli.cursor_x;
            text_buf[pos] = 0x0720; // Space
        }
    } else {
        // Regular character
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

// Put string
void cli_puts(const char* str) {
    while (*str) {
        cli_putchar(*str++);
    }
}

// Scroll screen up one line
void cli_scroll_up(void) {
    volatile unsigned short* text_buf = (volatile unsigned short*)DISPLAY_TEXT_BASE;
    
    // Move all lines up
    for (int y = 0; y < TEXT_ROWS - 1; y++) {
        for (int x = 0; x < TEXT_COLS; x++) {
            text_buf[y * TEXT_COLS + x] = text_buf[(y + 1) * TEXT_COLS + x];
        }
    }
    
    // Clear bottom line
    for (int x = 0; x < TEXT_COLS; x++) {
        text_buf[(TEXT_ROWS - 1) * TEXT_COLS + x] = 0x0720;
    }
}

// Simple printf implementation
void cli_printf(const char* format, ...) {
    // Very basic printf - just handle %s, %d, %x for now
    char buffer[256];
    int* args = (int*)(&format + 1);
    int arg_index = 0;
    int buf_pos = 0;
    
    while (*format && buf_pos < 255) {
        if (*format == '%' && *(format + 1)) {
            format++;
            switch (*format) {
                case 's': {
                    char* str = (char*)args[arg_index++];
                    while (*str && buf_pos < 255) {
                        buffer[buf_pos++] = *str++;
                    }
                    break;
                }
                case 'd': {
                    int val = args[arg_index++];
                    // Simple integer to string conversion
                    if (val == 0) {
                        buffer[buf_pos++] = '0';
                    } else {
                        char temp[32];
                        int temp_pos = 0;
                        int is_negative = val < 0;
                        if (is_negative) val = -val;
                        
                        while (val > 0) {
                            temp[temp_pos++] = '0' + (val % 10);
                            val /= 10;
                        }
                        
                        if (is_negative) buffer[buf_pos++] = '-';
                        
                        while (temp_pos > 0 && buf_pos < 255) {
                            buffer[buf_pos++] = temp[--temp_pos];
                        }
                    }
                    break;
                }
                case 'x': {
                    int val = args[arg_index++];
                    // Hex conversion
                    char temp[16];
                    int temp_pos = 0;
                    
                    if (val == 0) {
                        buffer[buf_pos++] = '0';
                    } else {
                        while (val > 0) {
                            int digit = val & 0xF;
                            temp[temp_pos++] = (digit < 10) ? ('0' + digit) : ('A' + digit - 10);
                            val >>= 4;
                        }
                        
                        while (temp_pos > 0 && buf_pos < 255) {
                            buffer[buf_pos++] = temp[--temp_pos];
                        }
                    }
                    break;
                }
                default:
                    buffer[buf_pos++] = *format;
                    break;
            }
        } else {
            buffer[buf_pos++] = *format;
        }
        format++;
    }
    
    buffer[buf_pos] = '\0';
    cli_puts(buffer);
}

// Graphics functions
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
    // Simple line drawing using Bresenham's algorithm
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
    // Draw rectangle outline
    gfx_draw_line(x, y, x + width - 1, y, color);                    // Top
    gfx_draw_line(x, y + height - 1, x + width - 1, y + height - 1, color); // Bottom
    gfx_draw_line(x, y, x, y + height - 1, color);                   // Left
    gfx_draw_line(x + width - 1, y, x + width - 1, y + height - 1, color);  // Right
}

void gfx_fill_rect(int x, int y, int width, int height, int color) {
    for (int dy = 0; dy < height; dy++) {
        for (int dx = 0; dx < width; dx++) {
            gfx_set_pixel(x + dx, y + dy, color);
        }
    }
}

// Command implementations
void cmd_help(int argc, char** argv) {
    cli_puts("Available commands:\n");
    for (int i = 0; commands[i].name; i++) {
        cli_printf("  %s - %s\n", commands[i].name, commands[i].help);
    }
}

void cmd_clear(int argc, char** argv) {
    cli_clear_screen();
}

void cmd_echo(int argc, char** argv) {
    for (int i = 1; i < argc; i++) {
        cli_puts(argv[i]);
        if (i < argc - 1) cli_puts(" ");
    }
    cli_puts("\n");
}

void cmd_color(int argc, char** argv) {
    if (argc >= 3) {
        int fg = simple_atoi(argv[1]);
        int bg = simple_atoi(argv[2]);
        cli_set_color(fg, bg);
        cli_printf("Color set to fg=%d bg=%d\n", fg, bg);
    } else {
        cli_puts("Usage: color <fg> <bg>\n");
    }
}

void cmd_mode(int argc, char** argv) {
    if (argc >= 2) {
        int mode = simple_atoi(argv[1]);
        WRITE_REG(MODE_REG, mode);
        cli_printf("Display mode set to %d\n", mode);
    } else {
        cli_puts("Usage: mode <0|1|2>\n");
    }
}

void cmd_pixel(int argc, char** argv) {
    if (argc >= 4) {
        int x = simple_atoi(argv[1]);
        int y = simple_atoi(argv[2]);
        int color = simple_atoi(argv[3]);
        gfx_set_pixel(x, y, color);
        cli_printf("Pixel set at (%d,%d) color=%d\n", x, y, color);
    } else {
        cli_puts("Usage: pixel <x> <y> <color>\n");
    }
}

void cmd_line(int argc, char** argv) {
    if (argc >= 6) {
        int x1 = simple_atoi(argv[1]);
        int y1 = simple_atoi(argv[2]);
        int x2 = simple_atoi(argv[3]);
        int y2 = simple_atoi(argv[4]);
        int color = simple_atoi(argv[5]);
        gfx_draw_line(x1, y1, x2, y2, color);
        cli_printf("Line drawn from (%d,%d) to (%d,%d)\n", x1, y1, x2, y2);
    } else {
        cli_puts("Usage: line <x1> <y1> <x2> <y2> <color>\n");
    }
}

void cmd_rect(int argc, char** argv) {
    if (argc >= 6) {
        int x = simple_atoi(argv[1]);
        int y = simple_atoi(argv[2]);
        int w = simple_atoi(argv[3]);
        int h = simple_atoi(argv[4]);
        int color = simple_atoi(argv[5]);
        gfx_draw_rect(x, y, w, h, color);
        cli_printf("Rectangle drawn at (%d,%d) size %dx%d\n", x, y, w, h);
    } else {
        cli_puts("Usage: rect <x> <y> <width> <height> <color>\n");
    }
}

// Simple string to integer conversion
int simple_atoi(const char* str) {
    int result = 0;
    int sign = 1;
    
    if (*str == '-') {
        sign = -1;
        str++;
    }
    
    while (*str >= '0' && *str <= '9') {
        result = result * 10 + (*str - '0');
        str++;
    }
    
    return result * sign;
}

// Simple command parsing
int parse_command(const char* input, char** argv, int max_args) {
    static char cmd_buffer[256];
    int argc = 0;
    int i = 0, j = 0;
    
    // Copy input to buffer
    while (input[i] && j < 255) {
        cmd_buffer[j++] = input[i++];
    }
    cmd_buffer[j] = '\0';
    
    // Parse arguments
    i = 0;
    while (cmd_buffer[i] && argc < max_args) {
        // Skip whitespace
        while (cmd_buffer[i] == ' ' || cmd_buffer[i] == '\t') i++;
        
        if (cmd_buffer[i]) {
            argv[argc++] = &cmd_buffer[i];
            
            // Find end of argument
            while (cmd_buffer[i] && cmd_buffer[i] != ' ' && cmd_buffer[i] != '\t') i++;
            
            // Null terminate
            if (cmd_buffer[i]) {
                cmd_buffer[i++] = '\0';
            }
        }
    }
    
    return argc;
}

// Process command
void cli_process_command(const char* cmd) {
    char* argv[16];
    int argc = parse_command(cmd, argv, 16);
    
    if (argc > 0) {
        // Find and execute command
        for (int i = 0; commands[i].name; i++) {
            if (string_compare(argv[0], commands[i].name) == 0) {
                commands[i].handler(argc, argv);
                return;
            }
        }
        
        cli_printf("Unknown command: %s\n", argv[0]);
        cli_puts("Type 'help' for available commands\n");
    }
}

// Simple string comparison
int string_compare(const char* str1, const char* str2) {
    while (*str1 && *str2) {
        if (*str1 != *str2) {
            return *str1 - *str2;
        }
        str1++;
        str2++;
    }
    return *str1 - *str2;
}

// Main CLI loop
void cli_main_loop(void) {
    char input_buffer[256];
    
    while (1) {
        // Show prompt
        cli_puts("> ");
        
        // Get input (this would need keyboard input implementation)
        cli_gets(input_buffer, sizeof(input_buffer));
        
        // Process command
        if (input_buffer[0]) {
            cli_process_command(input_buffer);
        }
    }
}

// Placeholder for keyboard input - would need actual keyboard controller
void cli_gets(char* buffer, int max_len) {
    // This is a placeholder - actual implementation would read from keyboard
    // For now, just simulate some commands for testing
    static int demo_step = 0;
    static const char* demo_commands[] = {
        "help",
        "color 14 1",
        "echo Hello World!",
        "mode 1",
        "pixel 100 100 15",
        "line 0 0 639 479 12",
        "rect 50 50 200 100 10",
        ""
    };
    
    if (demo_step < 7) {
        string_copy(buffer, demo_commands[demo_step++]);
        cli_puts(buffer);
        cli_puts("\n");
    } else {
        buffer[0] = '\0';
    }
}

// Simple string copy
void string_copy(char* dest, const char* src) {
    while (*src) {
        *dest++ = *src++;
    }
    *dest = '\0';
}
