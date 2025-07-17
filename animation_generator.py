#!/usr/bin/env python3
"""
Animation Generator for FramebufferTab Live Monitoring
Creates animated PPM sequences to test the live monitor functionality
"""

import time
import math
import os

def create_ppm_header(width, height):
    """Create PPM P6 header"""
    return f"P6\n{width} {height}\n255\n".encode('ascii')

def generate_bouncing_ball_frame(width, height, frame_num, ball_radius=20):
    """Generate a frame with a bouncing ball animation"""
    # Ball position calculations
    t = frame_num * 0.1  # Time parameter
    
    # Bouncing ball physics
    ball_x = int((width - 2 * ball_radius) * (0.5 + 0.4 * math.sin(t)))
    ball_y = int((height - 2 * ball_radius) * abs(math.sin(t * 1.3)))
    
    # Ball color (changes with time)
    ball_color = (
        int(128 + 127 * math.sin(t)),
        int(128 + 127 * math.sin(t + 2.094)),  # 120 degrees phase shift
        int(128 + 127 * math.sin(t + 4.188))   # 240 degrees phase shift
    )
    
    # Create pixel data
    pixels = []
    for y in range(height):
        for x in range(width):
            # Calculate distance from ball center
            dx = x - (ball_x + ball_radius)
            dy = y - (ball_y + ball_radius)
            distance = math.sqrt(dx*dx + dy*dy)
            
            if distance <= ball_radius:
                # Inside ball - use ball color with gradient
                gradient = 1.0 - (distance / ball_radius) * 0.5
                r = int(ball_color[0] * gradient)
                g = int(ball_color[1] * gradient)
                b = int(ball_color[2] * gradient)
            else:
                # Background - dark blue gradient
                bg_intensity = int(20 + 10 * math.sin(x * 0.02) * math.sin(y * 0.02))
                r = bg_intensity // 3
                g = bg_intensity // 3
                b = bg_intensity
            
            # Clamp values
            r = max(0, min(255, r))
            g = max(0, min(255, g))
            b = max(0, min(255, b))
            
            pixels.extend([r, g, b])
    
    return bytes(pixels)

def generate_plasma_frame(width, height, frame_num):
    """Generate a plasma effect frame"""
    t = frame_num * 0.05
    
    pixels = []
    for y in range(height):
        for x in range(width):
            # Plasma calculations
            v1 = math.sin((x * 0.02) + t)
            v2 = math.sin((y * 0.03) + t * 1.5)
            v3 = math.sin(((x + y) * 0.015) + t * 0.7)
            v4 = math.sin(math.sqrt(x*x + y*y) * 0.01 + t * 2)
            
            plasma = (v1 + v2 + v3 + v4) / 4
            
            # Convert to RGB
            r = int(128 + 127 * math.sin(plasma * math.pi))
            g = int(128 + 127 * math.sin(plasma * math.pi + 2.094))
            b = int(128 + 127 * math.sin(plasma * math.pi + 4.188))
            
            pixels.extend([r, g, b])
    
    return bytes(pixels)

def generate_mandelbrot_zoom_frame(width, height, frame_num):
    """Generate a zooming Mandelbrot set frame"""
    zoom = 1.0 + frame_num * 0.1
    center_x, center_y = -0.7269, 0.1889  # Interesting area
    
    pixels = []
    for y in range(height):
        for x in range(width):
            # Map pixel to complex plane
            real = (x - width/2) / (width/4) / zoom + center_x
            imag = (y - height/2) / (height/4) / zoom + center_y
            
            # Mandelbrot iteration
            c = complex(real, imag)
            z = 0
            iterations = 0
            max_iter = 50
            
            while iterations < max_iter and abs(z) < 2:
                z = z*z + c
                iterations += 1
            
            # Color based on iterations
            if iterations == max_iter:
                r, g, b = 0, 0, 0  # Black for points in set
            else:
                # Color gradient for points outside set
                t = iterations / max_iter
                r = int(255 * (0.5 + 0.5 * math.sin(6.28 * t)))
                g = int(255 * (0.5 + 0.5 * math.sin(6.28 * t + 2.094)))
                b = int(255 * (0.5 + 0.5 * math.sin(6.28 * t + 4.188)))
            
            pixels.extend([r, g, b])
    
    return bytes(pixels)

def run_animation(animation_type="bouncing_ball", width=320, height=240, frame_delay=0.033):
    """Run continuous animation"""
    output_path = "/Users/rajanpanneerselvam/work/hdl/temp/reports/framebuffer.ppm"
    
    # Ensure output directory exists
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    
    print(f"Starting {animation_type} animation at {output_path}")
    print(f"Resolution: {width}x{height}, Frame delay: {frame_delay:.3f}s")
    print("Press Ctrl+C to stop...")
    
    frame_num = 0
    
    try:
        while True:
            # Generate frame data based on animation type
            if animation_type == "bouncing_ball":
                pixel_data = generate_bouncing_ball_frame(width, height, frame_num)
            elif animation_type == "plasma":
                pixel_data = generate_plasma_frame(width, height, frame_num)
            elif animation_type == "mandelbrot":
                pixel_data = generate_mandelbrot_zoom_frame(width, height, frame_num)
            else:
                raise ValueError(f"Unknown animation type: {animation_type}")
            
            # Write PPM file
            with open(output_path, 'wb') as f:
                f.write(create_ppm_header(width, height))
                f.write(pixel_data)
            
            print(f"\rFrame {frame_num:4d} generated", end="", flush=True)
            frame_num += 1
            
            # Wait for next frame
            time.sleep(frame_delay)
            
    except KeyboardInterrupt:
        print(f"\nAnimation stopped after {frame_num} frames")

if __name__ == "__main__":
    import sys
    
    if len(sys.argv) > 1:
        animation_type = sys.argv[1]
    else:
        animation_type = "bouncing_ball"
    
    # Validate animation type
    valid_types = ["bouncing_ball", "plasma", "mandelbrot"]
    if animation_type not in valid_types:
        print(f"Invalid animation type. Choose from: {', '.join(valid_types)}")
        sys.exit(1)
    
    # Default to smooth 30 FPS
    run_animation(animation_type, frame_delay=1.0/30.0)
