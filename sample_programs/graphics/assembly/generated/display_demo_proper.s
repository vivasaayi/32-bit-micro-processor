// Simple Display Demo - Assembly
// Demonstrates text mode display output

main:
// Set up display in text mode
LOADI R1, 0xFF000  // Load display base address (high part)
SHL R1, R1, 16     // Shift to get 0xFF000000
LOADI R2, 0        // Text mode = 0
STORE R2, R1, 0    // Write to mode register

// Set up text buffer address
LOADI R3, 0xFF001  // Text buffer high part
SHL R3, R3, 16     // Get 0xFF001000

// Write "HELLO" - each character is 16-bit
LOADI R4, 0x0F48   // 'H' with white on black
STORE R4, R3, 0

LOADI R4, 0x0F45   // 'E'
STORE R4, R3, 2

LOADI R4, 0x0F4C   // 'L'
STORE R4, R3, 4

LOADI R4, 0x0F4C   // 'L'
STORE R4, R3, 6

LOADI R4, 0x0F4F   // 'O'
STORE R4, R3, 8

// Write "DISPLAY" on second line
LOADI R4, 0x0A44   // 'D' with light green
STORE R4, R3, 160

LOADI R4, 0x0A49   // 'I'
STORE R4, R3, 162

LOADI R4, 0x0A53   // 'S'
STORE R4, R3, 164

LOADI R4, 0x0A50   // 'P'
STORE R4, R3, 166

LOADI R4, 0x0A4C   // 'L'
STORE R4, R3, 168

LOADI R4, 0x0A41   // 'A'
STORE R4, R3, 170

LOADI R4, 0x0A59   // 'Y'
STORE R4, R3, 172

// Switch to graphics mode
LOADI R2, 1        // Graphics mode = 1
STORE R2, R1, 0    // Write to mode register

// Set up graphics buffer
LOADI R5, 0xFF002  // Graphics buffer high part
SHL R5, R5, 16     // Get 0xFF002000

// Draw a simple pattern (rectangle from 100,100 to 200,200)
LOADI R6, 100      // Y counter

draw_y_loop:
LOADI R7, 100      // X counter

draw_x_loop:
// Calculate pixel address: base + (y * 640 + x)
LOADI R8, 640      // Screen width
MUL R9, R6, R8     // y * 640
ADD R9, R9, R7     // + x
ADD R10, R5, R9    // + base address

// Calculate simple color pattern
ADD R11, R6, R7    // x + y
ANDI R11, R11, 255 // Keep lower 8 bits for color

// Store pixel (using byte store)
STORE R11, R10, 0

// Increment X
ADDI R7, R7, 1
SUBI R12, R7, 200  // Check if x < 200
BLT R12, R0, draw_x_loop

// Increment Y
ADDI R6, R6, 1
SUBI R12, R6, 200  // Check if y < 200
BLT R12, R0, draw_y_loop

// Infinite loop to keep display active
main_loop:
JMP main_loop
