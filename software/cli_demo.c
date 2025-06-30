/*
 * CLI Demo Program for Custom RISC Processor
 * Demonstrates text mode CLI and graphics capabilities
 */

#include "cli.h"

// Forward declarations
int simple_atoi(const char* str);
int parse_command(const char* input, char** argv, int max_args);
int string_compare(const char* str1, const char* str2);
void string_copy(char* dest, const char* src);

int main() {
    // Initialize the CLI system
    cli_init();
    
    cli_puts("=== Display System Demo ===\n\n");
    
    // Demonstrate text mode features
    cli_puts("1. Text Mode Features:\n");
    
    // Color demonstration
    cli_set_color(COLOR_YELLOW, COLOR_BLUE);
    cli_puts("   * Colored text support\n");
    
    cli_set_color(COLOR_GREEN, COLOR_BLACK);
    cli_puts("   * Multiple colors available\n");
    
    cli_set_color(COLOR_WHITE, COLOR_BLACK);
    cli_puts("   * Easy color switching\n\n");
    
    // Cursor positioning
    cli_puts("2. Cursor Control:\n");
    cli_set_cursor(10, cli.cursor_y);
    cli_puts("This text is indented!\n");
    
    cli_set_cursor(0, cli.cursor_y);
    cli_puts("   Back to normal position\n\n");
    
    // Graphics mode demonstration
    cli_puts("3. Switching to Graphics Mode...\n");
    
    // Wait a moment (simple delay)
    for (int i = 0; i < 100000; i++) {
        // Simple delay loop
    }
    
    // Switch to graphics mode
    gfx_init();
    
    // Clear screen with blue background
    gfx_clear_screen(COLOR_BLUE);
    
    // Draw some graphics
    // Draw a white border
    gfx_draw_rect(10, 10, 620, 460, COLOR_WHITE);
    
    // Draw some colored rectangles
    gfx_fill_rect(50, 50, 100, 80, COLOR_RED);
    gfx_fill_rect(200, 50, 100, 80, COLOR_GREEN);
    gfx_fill_rect(350, 50, 100, 80, COLOR_YELLOW);
    
    // Draw some lines
    gfx_draw_line(50, 200, 550, 200, COLOR_WHITE);
    gfx_draw_line(50, 250, 550, 350, COLOR_LTGREEN);
    gfx_draw_line(550, 250, 50, 350, COLOR_LTRED);
    
    // Draw a pattern
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
    
    // The bottom area should now show text over graphics
    cli_set_cursor(0, 20);
    cli_set_color(COLOR_BRIGHT_WHITE, COLOR_BLACK);
    cli_puts("Mixed Mode: Graphics + Text Overlay");
    
    cli_set_cursor(0, 21);
    cli_puts("Text appears over graphics background");
    
    cli_set_cursor(0, 23);
    cli_puts("CLI Demo Complete!");
    
    // Simple command loop simulation
    cli_set_cursor(0, 24);
    cli_puts("> ");
    
    // Demonstrate some commands
    const char* demo_commands[] = {
        "help",
        "echo Graphics and CLI working!",
        "color 14 4",
        "echo Colorful text!",
        ""
    };
    
    for (int cmd_idx = 0; demo_commands[cmd_idx][0]; cmd_idx++) {
        // Simulate typing the command
        cli_puts(demo_commands[cmd_idx]);
        cli_puts("\n");
        
        // Process the command
        cli_process_command(demo_commands[cmd_idx]);
        
        // Show prompt for next command
        cli_puts("> ");
        
        // Delay between commands
        for (int i = 0; i < 200000; i++) {
            // Delay
        }
    }
    
    cli_puts("Demo finished. System ready for interactive use.\n");
    
    // In a real system, this would start the interactive CLI loop
    // cli_main_loop();
    
    return 0;
}
