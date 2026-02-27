#!/usr/bin/env python3
"""
Animated framebuffer generator for testing the Java UI
Creates a series of PPM files with animated patterns
"""

import os
import time
import math

def create_animated_framebuffer():
    """Create animated test framebuffers"""
    width, height = 320, 240
    
    os.makedirs('../temp/reports', exist_ok=True)
    
    print("Starting animated framebuffer generation...")
    print("The Java UI should show animated patterns when Auto Refresh is enabled")
    print("Press Ctrl+C to stop")
    
    frame = 0
    try:
        while True:
            with open('../temp/reports/framebuffer.ppm', 'wb') as f:
                # PPM P6 header
                f.write(b'P6\n')
                f.write(f'# Animated frame {frame}\n'.encode())
                f.write(f'{width} {height}\n'.encode())
                f.write(b'255\n')
                
                # Generate animated pattern
                for y in range(height):
                    for x in range(width):
                        # Create moving wave patterns
                        wave1 = math.sin((x + frame * 2) * 0.1) * 127 + 128
                        wave2 = math.cos((y + frame * 3) * 0.08) * 127 + 128
                        wave3 = math.sin((x + y + frame * 4) * 0.05) * 127 + 128
                        
                        r = int(wave1) & 0xFF
                        g = int(wave2) & 0xFF  
                        b = int(wave3) & 0xFF
                        
                        f.write(bytes([r, g, b]))
            
            print(f"Generated frame {frame}")
            frame += 1
            time.sleep(0.5)  # 2 FPS animation
            
    except KeyboardInterrupt:
        print("\nAnimation stopped")

if __name__ == '__main__':
    create_animated_framebuffer()
