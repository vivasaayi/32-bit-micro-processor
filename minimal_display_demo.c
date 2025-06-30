/*
 * Minimal Display Demo for Custom RISC Processor
 */

int main() {
    // Display controller addresses
    unsigned int mode_reg = 0xFF000000;
    unsigned int text_base = 0xFF001000;
    unsigned int gfx_base = 0xFF002000;
    
    // Set text mode
    *((volatile unsigned int*)mode_reg) = 0;
    
    // Write "HELLO" to display
    volatile unsigned short* text_buffer = (volatile unsigned short*)text_base;
    text_buffer[0] = 0x0F48;  // 'H' with white on black
    text_buffer[1] = 0x0F45;  // 'E'
    text_buffer[2] = 0x0F4C;  // 'L'
    text_buffer[3] = 0x0F4C;  // 'L'
    text_buffer[4] = 0x0F4F;  // 'O'
    
    // Write "DISPLAY" on next line
    int line2 = 80;
    text_buffer[line2 + 0] = 0x0A44;  // 'D' with light green
    text_buffer[line2 + 1] = 0x0A49;  // 'I'
    text_buffer[line2 + 2] = 0x0A53;  // 'S'
    text_buffer[line2 + 3] = 0x0A50;  // 'P'
    text_buffer[line2 + 4] = 0x0A4C;  // 'L'
    text_buffer[line2 + 5] = 0x0A41;  // 'A'
    text_buffer[line2 + 6] = 0x0A59;  // 'Y'
    
    // Switch to graphics mode
    *((volatile unsigned int*)mode_reg) = 1;
    
    // Draw some pixels
    volatile unsigned char* framebuffer = (volatile unsigned char*)gfx_base;
    
    // Simple pattern
    int x, y;
    for (y = 50; y < 150; y++) {
        for (x = 50; x < 250; x++) {
            int pixel = y * 640 + x;
            framebuffer[pixel] = x + y;
        }
    }
    
    // Keep running
    while (1) {
        // Simple delay
        int i;
        for (i = 0; i < 10000; i++) {
            // Do nothing
        }
    }
    
    return 0;
}
