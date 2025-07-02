// 102_interactive_ui.c - Interactive User Interface Framework
// Demonstrates interactive graphics with user input simulation

// UI Framework configuration
#define FB_BASE_ADDR 0x8000  // 65536
#define FB_WIDTH 320
#define FB_HEIGHT 240
#define INPUT_BASE_ADDR 0x20000  // 131072 - Simulated input region

// UI Colors
#define UI_BACKGROUND 0x2D2D30FF  // Dark gray
#define UI_BUTTON     0x007ACCFF  // Blue
#define UI_BUTTON_HOVER 0x1E90FFFF // Light blue
#define UI_BUTTON_PRESSED 0x4169E1FF // Royal blue
#define UI_TEXT       0xFFFFFFFF  // White
#define UI_BORDER     0x808080FF  // Gray
#define UI_HIGHLIGHT  0x00FF00FF  // Green
#define UI_ERROR      0xFF4444FF  // Red

// UI Element types
typedef struct {
    int x, y, width, height;
    unsigned int color;
    unsigned int text_color;
    int is_pressed;
    int is_hovered;
    char label[16];
} UIButton;

typedef struct {
    int x, y, width, height;
    int value;
    int min_value, max_value;
    unsigned int bar_color;
    unsigned int bg_color;
    char label[16];
} UISlider;

typedef struct {
    int x, y;
    int is_pressed;
    int last_x, last_y;
} MouseState;

// Global UI state
MouseState mouse = {160, 120, 0, 160, 120};
UIButton buttons[5];
UISlider sliders[3];
int current_screen = 0;  // 0=main, 1=controls, 2=graphics
int animation_speed = 5;
int selected_color = 0xFF0000FF; // Red

// Basic drawing functions
void set_pixel(int x, int y, unsigned int color) {
    if (x >= 0 && x < FB_WIDTH && y >= 0 && y < FB_HEIGHT) {
        unsigned int *framebuffer = (unsigned int*)FB_BASE_ADDR;
        framebuffer[y * FB_WIDTH + x] = color;
    }
}

void fill_rectangle(int x0, int y0, int x1, int y1, unsigned int color) {
    if (x0 > x1) { int temp = x0; x0 = x1; x1 = temp; }
    if (y0 > y1) { int temp = y0; y0 = y1; y1 = temp; }
    
    for (int y = y0; y <= y1; y++) {
        for (int x = x0; x <= x1; x++) {
            set_pixel(x, y, color);
        }
    }
}

void draw_rectangle(int x0, int y0, int x1, int y1, unsigned int color) {
    // Top and bottom edges
    for (int x = x0; x <= x1; x++) {
        set_pixel(x, y0, color);
        set_pixel(x, y1, color);
    }
    // Left and right edges
    for (int y = y0; y <= y1; y++) {
        set_pixel(x0, y, color);
        set_pixel(x1, y, color);
    }
}

// Simple text rendering (draws a rectangular pattern for each character)
void draw_char(int x, int y, char c, unsigned int color) {
    // Simple 5x7 character patterns (simplified)
    int patterns[26][7] = {
        // A
        {0x0E, 0x11, 0x11, 0x1F, 0x11, 0x11, 0x11},
        // B  
        {0x1E, 0x11, 0x11, 0x1E, 0x11, 0x11, 0x1E},
        // Add more patterns as needed...
    };
    
    if (c >= 'A' && c <= 'Z') {
        int pattern_idx = c - 'A';
        for (int row = 0; row < 7; row++) {
            for (int col = 0; col < 5; col++) {
                if (patterns[pattern_idx][row] & (1 << (4-col))) {
                    set_pixel(x + col, y + row, color);
                }
            }
        }
    } else {
        // Simple fallback - draw a rectangle for unknown chars
        fill_rectangle(x, y, x + 4, y + 6, color);
    }
}

void draw_text(int x, int y, const char* text, unsigned int color) {
    int offset = 0;
    while (*text) {
        if (*text >= 'A' && *text <= 'Z') {
            draw_char(x + offset, y, *text, color);
        } else if (*text >= 'a' && *text <= 'z') {
            draw_char(x + offset, y, *text - 32, color); // Convert to uppercase
        } else {
            // Space or other character
            fill_rectangle(x + offset, y, x + offset + 4, y + 6, UI_BACKGROUND);
        }
        offset += 6;
        text++;
    }
}

// UI Button functions
void init_button(UIButton* btn, int x, int y, int w, int h, const char* label, unsigned int color) {
    btn->x = x; btn->y = y; btn->width = w; btn->height = h;
    btn->color = color; btn->text_color = UI_TEXT;
    btn->is_pressed = 0; btn->is_hovered = 0;
    
    // Copy label (simple string copy)
    int i = 0;
    while (label[i] && i < 15) {
        btn->label[i] = label[i];
        i++;
    }
    btn->label[i] = '\0';
}

void draw_button(UIButton* btn) {
    unsigned int current_color = btn->color;
    if (btn->is_pressed) {
        current_color = UI_BUTTON_PRESSED;
    } else if (btn->is_hovered) {
        current_color = UI_BUTTON_HOVER;
    }
    
    // Draw button background
    fill_rectangle(btn->x, btn->y, btn->x + btn->width, btn->y + btn->height, current_color);
    
    // Draw button border
    draw_rectangle(btn->x, btn->y, btn->x + btn->width, btn->y + btn->height, UI_BORDER);
    
    // Draw button text (centered)
    int text_x = btn->x + (btn->width - 6 * 4) / 2; // Approximate centering
    int text_y = btn->y + (btn->height - 7) / 2;
    draw_text(text_x, text_y, btn->label, btn->text_color);
}

int is_point_in_button(UIButton* btn, int x, int y) {
    return (x >= btn->x && x <= btn->x + btn->width && 
            y >= btn->y && y <= btn->y + btn->height);
}

// UI Slider functions
void init_slider(UISlider* slider, int x, int y, int w, int h, const char* label, int min_val, int max_val, int initial_val) {
    slider->x = x; slider->y = y; slider->width = w; slider->height = h;
    slider->min_value = min_val; slider->max_value = max_val; slider->value = initial_val;
    slider->bar_color = UI_BUTTON; slider->bg_color = UI_BACKGROUND;
    
    // Copy label
    int i = 0;
    while (label[i] && i < 15) {
        slider->label[i] = label[i];
        i++;
    }
    slider->label[i] = '\0';
}

void draw_slider(UISlider* slider) {
    // Draw background
    fill_rectangle(slider->x, slider->y, slider->x + slider->width, slider->y + slider->height, slider->bg_color);
    
    // Draw border
    draw_rectangle(slider->x, slider->y, slider->x + slider->width, slider->y + slider->height, UI_BORDER);
    
    // Calculate slider position
    int range = slider->max_value - slider->min_value;
    int bar_width = ((slider->value - slider->min_value) * (slider->width - 4)) / range;
    
    // Draw filled portion
    if (bar_width > 0) {
        fill_rectangle(slider->x + 2, slider->y + 2, slider->x + 2 + bar_width, slider->y + slider->height - 2, slider->bar_color);
    }
    
    // Draw label above slider
    draw_text(slider->x, slider->y - 10, slider->label, UI_TEXT);
}

// Simulate mouse input based on simple patterns
void update_mouse_simulation(int frame) {
    // Simulate mouse movement and clicks
    mouse.last_x = mouse.x;
    mouse.last_y = mouse.y;
    
    // Create circular mouse movement
    mouse.x = 160 + (int)(50.0 * cos(frame * 0.1));
    mouse.y = 120 + (int)(30.0 * sin(frame * 0.1));
    
    // Simulate clicks periodically
    mouse.is_pressed = (frame % 60 < 10) ? 1 : 0;
}

// Update UI element states based on mouse
void update_ui_elements() {
    // Update button states
    for (int i = 0; i < 5; i++) {
        buttons[i].is_hovered = is_point_in_button(&buttons[i], mouse.x, mouse.y);
        if (buttons[i].is_hovered && mouse.is_pressed) {
            buttons[i].is_pressed = 1;
        } else {
            buttons[i].is_pressed = 0;
        }
    }
    
    // Update slider values based on mouse interaction
    for (int i = 0; i < 3; i++) {
        if (mouse.is_pressed && mouse.y >= sliders[i].y && mouse.y <= sliders[i].y + sliders[i].height &&
            mouse.x >= sliders[i].x && mouse.x <= sliders[i].x + sliders[i].width) {
            
            int relative_x = mouse.x - sliders[i].x;
            int range = sliders[i].max_value - sliders[i].min_value;
            sliders[i].value = sliders[i].min_value + (relative_x * range) / sliders[i].width;
            
            // Clamp to range
            if (sliders[i].value < sliders[i].min_value) sliders[i].value = sliders[i].min_value;
            if (sliders[i].value > sliders[i].max_value) sliders[i].value = sliders[i].max_value;
        }
    }
}

// Handle button clicks
void handle_button_clicks() {
    if (buttons[0].is_pressed) { // Main Menu
        current_screen = 0;
    }
    if (buttons[1].is_pressed) { // Controls
        current_screen = 1;
    }
    if (buttons[2].is_pressed) { // Graphics
        current_screen = 2;
    }
    if (buttons[3].is_pressed) { // Color Picker
        selected_color = (selected_color == 0xFF0000FF) ? 0x00FF00FF : 
                        (selected_color == 0x00FF00FF) ? 0x0000FFFF : 0xFF0000FF;
    }
    if (buttons[4].is_pressed) { // Reset
        animation_speed = 5;
        selected_color = 0xFF0000FF;
        current_screen = 0;
    }
}

// Draw different screens
void draw_main_screen() {
    // Clear screen
    fill_rectangle(0, 0, FB_WIDTH-1, FB_HEIGHT-1, UI_BACKGROUND);
    
    // Draw title
    draw_text(100, 20, "RISC CPU UI DEMO", UI_TEXT);
    
    // Draw menu buttons
    draw_button(&buttons[0]); // Main
    draw_button(&buttons[1]); // Controls
    draw_button(&buttons[2]); // Graphics
    
    // Draw status info
    draw_text(20, 180, "INTERACTIVE MODE", UI_HIGHLIGHT);
    
    // Draw mouse cursor
    fill_rectangle(mouse.x-2, mouse.y-2, mouse.x+2, mouse.y+2, UI_TEXT);
}

void draw_controls_screen() {
    fill_rectangle(0, 0, FB_WIDTH-1, FB_HEIGHT-1, UI_BACKGROUND);
    
    draw_text(120, 20, "CONTROLS", UI_TEXT);
    
    // Draw sliders
    draw_slider(&sliders[0]); // Speed
    draw_slider(&sliders[1]); // Red component
    draw_slider(&sliders[2]); // Green component
    
    // Draw control buttons
    draw_button(&buttons[0]); // Back to main
    draw_button(&buttons[3]); // Color picker
    draw_button(&buttons[4]); // Reset
    
    // Show current values
    draw_text(20, 200, "SPEED:", UI_TEXT);
    draw_text(20, 210, "COLOR:", UI_TEXT);
    
    // Draw mouse cursor
    fill_rectangle(mouse.x-2, mouse.y-2, mouse.x+2, mouse.y+2, UI_TEXT);
}

void draw_graphics_screen() {
    fill_rectangle(0, 0, FB_WIDTH-1, FB_HEIGHT-1, UI_BACKGROUND);
    
    draw_text(120, 20, "GRAPHICS", UI_TEXT);
    
    // Draw animated graphics based on slider values
    int speed = sliders[0].value;
    int red = sliders[1].value;
    int green = sliders[2].value;
    
    // Create dynamic graphics
    for (int i = 0; i < 10; i++) {
        int x = 50 + i * 20;
        int y = 100 + (int)(20 * sin((speed + i) * 0.1));
        unsigned int color = (red << 24) | (green << 16) | (128 << 8) | 0xFF;
        fill_rectangle(x, y, x+15, y+15, color);
    }
    
    // Draw back button
    draw_button(&buttons[0]);
    
    // Draw mouse cursor
    fill_rectangle(mouse.x-2, mouse.y-2, mouse.x+2, mouse.y+2, UI_TEXT);
}

void delay(int cycles) {
    for (int i = 0; i < cycles; i++) {
        int dummy = i * 2;
    }
}

int main() {
    log_string("=== Interactive UI Demo ===\n");
    log_string("Starting interactive interface\n");
    
    // Initialize UI elements
    init_button(&buttons[0], 20, 50, 60, 25, "MAIN", UI_BUTTON);
    init_button(&buttons[1], 90, 50, 60, 25, "CTRL", UI_BUTTON);
    init_button(&buttons[2], 160, 50, 60, 25, "GFX", UI_BUTTON);
    init_button(&buttons[3], 230, 50, 60, 25, "COLOR", UI_BUTTON);
    init_button(&buttons[4], 230, 80, 60, 25, "RESET", UI_BUTTON);
    
    init_slider(&sliders[0], 50, 120, 200, 20, "SPEED", 1, 20, 5);
    init_slider(&sliders[1], 50, 160, 200, 20, "RED", 0, 255, 255);
    init_slider(&sliders[2], 50, 200, 200, 20, "GREEN", 0, 255, 0);
    
    log_string("UI elements initialized\n");
    
    // Main UI loop
    for (int frame = 0; frame < 200; frame++) {
        // Update simulation state
        update_mouse_simulation(frame);
        update_ui_elements();
        handle_button_clicks();
        
        // Draw current screen
        switch (current_screen) {
            case 0: draw_main_screen(); break;
            case 1: draw_controls_screen(); break;
            case 2: draw_graphics_screen(); break;
            default: draw_main_screen(); break;
        }
        
        delay(2000); // Slow down for visibility
    }
    
    log_string("Interactive UI demo completed\n");
    log_string("Check Java UI for interactive elements\n");
    
    return 1;
}
