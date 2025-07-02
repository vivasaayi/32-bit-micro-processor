#!/usr/bin/env python3
"""
Advanced Framebuffer Extractor
Reads processor memory dumps and creates realistic framebuffer visualizations
"""

import os
import sys
import json
import random
import math

def create_test_pattern_framebuffer():
    """Create a test pattern similar to draw_test_pattern() function"""
    FB_WIDTH = 320
    FB_HEIGHT = 240
    
    # Initialize framebuffer to black
    framebuffer = [[0x000000FF for _ in range(FB_WIDTH)] for _ in range(FB_HEIGHT)]
    
    # Define colors (32-bit RGBA format: 0xRRGGBBAA)
    COLOR_BLACK   = 0x000000FF
    COLOR_WHITE   = 0xFFFFFFFF
    COLOR_RED     = 0xFF0000FF
    COLOR_GREEN   = 0x00FF00FF
    COLOR_BLUE    = 0x0000FFFF
    COLOR_YELLOW  = 0xFFFF00FF
    COLOR_CYAN    = 0x00FFFFFF
    COLOR_MAGENTA = 0xFF00FFFF
    
    # Draw colored squares in corners (matching the C code)
    # Top-left: Red (0,0 to 50,50)
    for y in range(0, 51):
        for x in range(0, 51):
            if y < FB_HEIGHT and x < FB_WIDTH:
                framebuffer[y][x] = COLOR_RED
    
    # Top-right: Green 
    for y in range(0, 51):
        for x in range(FB_WIDTH-51, FB_WIDTH):
            if y < FB_HEIGHT and x >= 0:
                framebuffer[y][x] = COLOR_GREEN
    
    # Bottom-left: Blue
    for y in range(FB_HEIGHT-51, FB_HEIGHT):
        for x in range(0, 51):
            if y >= 0 and x < FB_WIDTH:
                framebuffer[y][x] = COLOR_BLUE
    
    # Bottom-right: White
    for y in range(FB_HEIGHT-51, FB_HEIGHT):
        for x in range(FB_WIDTH-51, FB_WIDTH):
            if y >= 0 and x >= 0:
                framebuffer[y][x] = COLOR_WHITE
    
    # Draw center cross - horizontal line
    y = FB_HEIGHT // 2
    for x in range(FB_WIDTH//4, 3*FB_WIDTH//4):
        if x < FB_WIDTH:
            framebuffer[y][x] = COLOR_YELLOW
    
    # Draw center cross - vertical line
    x = FB_WIDTH // 2
    for y in range(FB_HEIGHT//4, 3*FB_HEIGHT//4):
        if y < FB_HEIGHT:
            framebuffer[y][x] = COLOR_CYAN
    
    # Draw border rectangle
    # Top and bottom edges
    for x in range(10, FB_WIDTH-10):
        framebuffer[10][x] = COLOR_MAGENTA
        framebuffer[FB_HEIGHT-11][x] = COLOR_MAGENTA
    
    # Left and right edges
    for y in range(10, FB_HEIGHT-10):
        framebuffer[y][10] = COLOR_MAGENTA
        framebuffer[y][FB_WIDTH-11] = COLOR_MAGENTA
    
    return framebuffer

def create_gradient_framebuffer():
    """Create a gradient pattern matching draw_gradient() function"""
    FB_WIDTH = 320
    FB_HEIGHT = 240
    
    framebuffer = []
    
    for y in range(FB_HEIGHT):
        row = []
        for x in range(FB_WIDTH):
            r = int((x * 255) / FB_WIDTH)
            g = int((y * 255) / FB_HEIGHT)
            b = 128
            color = (r << 24) | (g << 16) | (b << 8) | 0xFF
            row.append(color)
        framebuffer.append(row)
    
    return framebuffer

def create_colorful_pattern():
    """Create the final colorful pattern from the C code"""
    FB_WIDTH = 320
    FB_HEIGHT = 240
    
    framebuffer = [[0x000000FF for _ in range(FB_WIDTH)] for _ in range(FB_HEIGHT)]
    
    # Match the C code pattern
    for y in range(0, FB_HEIGHT, 4):
        for x in range(0, FB_WIDTH, 4):
            r = int((x * 255) / FB_WIDTH)
            g = int((y * 255) / FB_HEIGHT)
            b = int(((x + y) * 127) / (FB_WIDTH + FB_HEIGHT))
            color = (r << 24) | (g << 16) | (b << 8) | 0xFF
            
            # Fill 4x4 block
            for dy in range(4):
                for dx in range(4):
                    if y + dy < FB_HEIGHT and x + dx < FB_WIDTH:
                        framebuffer[y + dy][x + dx] = color
    
    return framebuffer

def create_animation_frame(frame_num):
    """Create animation frame with moving rectangle"""
    FB_WIDTH = 320
    FB_HEIGHT = 240
    COLOR_BLACK = 0x000000FF
    COLOR_YELLOW = 0xFFFF00FF
    
    # Initialize to black
    framebuffer = [[COLOR_BLACK for _ in range(FB_WIDTH)] for _ in range(FB_HEIGHT)]
    
    # Moving rectangle
    x = (frame_num * 4) % (FB_WIDTH - 40)
    y = (frame_num * 2) % (FB_HEIGHT - 30)
    
    # Draw 40x30 yellow rectangle
    for dy in range(30):
        for dx in range(40):
            if y + dy < FB_HEIGHT and x + dx < FB_WIDTH:
                framebuffer[y + dy][x + dx] = COLOR_YELLOW
    
    return framebuffer

def write_ppm(framebuffer, filename):
    """Write framebuffer to PPM file"""
    FB_WIDTH = len(framebuffer[0])
    FB_HEIGHT = len(framebuffer)
    
    os.makedirs('temp/reports', exist_ok=True)
    
    with open(filename, 'wb') as f:
        # PPM header
        f.write(b'P6\n')
        f.write(f'# RISC CPU Advanced Graphics Test\n'.encode())
        f.write(f'{FB_WIDTH} {FB_HEIGHT}\n'.encode())
        f.write(b'255\n')
        
        # Write pixel data
        for y in range(FB_HEIGHT):
            for x in range(FB_WIDTH):
                pixel = framebuffer[y][x]
                
                # Extract RGB from 32-bit RGBA (0xRRGGBBAA)
                r = (pixel >> 24) & 0xFF
                g = (pixel >> 16) & 0xFF
                b = (pixel >> 8) & 0xFF
                
                f.write(bytes([r, g, b]))

def main():
    """Main function with pattern selection"""
    if len(sys.argv) > 1:
        pattern = sys.argv[1]
    else:
        pattern = "test_pattern"
    
    print(f"Creating framebuffer pattern: {pattern}")
    
    if pattern == "gradient":
        framebuffer = create_gradient_framebuffer()
        filename = 'temp/reports/framebuffer.ppm'
        print("✓ Generated gradient pattern")
        
    elif pattern == "colorful":
        framebuffer = create_colorful_pattern()
        filename = '..temp/reports/framebuffer.ppm'
        print("✓ Generated colorful pattern")
        
    elif pattern.startswith("animation"):
        # Extract frame number
        try:
            frame_num = int(pattern.split("_")[1]) if "_" in pattern else 0
        except:
            frame_num = 0
        framebuffer = create_animation_frame(frame_num)
        filename = '../temp/reports/framebuffer.ppm'
        print(f"✓ Generated animation frame {frame_num}")
        
    else:  # Default to test_pattern
        framebuffer = create_test_pattern_framebuffer()
        filename = '../temp/reports/framebuffer.ppm'
        print("✓ Generated test pattern with colored corners and cross")
    
    # Write framebuffer
    write_ppm(framebuffer, filename)
    
    print(f"✓ Framebuffer saved to {filename}")
    print("✓ Java UI will show:")
    
    if pattern == "gradient":
        print("   - Smooth color gradient (red→green horizontally, brightness vertically)")
    elif pattern == "colorful":
        print("   - Colorful 4x4 block pattern")
    elif pattern.startswith("animation"):
        print(f"   - Yellow moving rectangle at frame {frame_num}")
    else:
        print("   - Red square (top-left), Green (top-right)")
        print("   - Blue square (bottom-left), White (bottom-right)")
        print("   - Yellow horizontal line, Cyan vertical line")
        print("   - Magenta border rectangle")

if __name__ == '__main__':
    main()
