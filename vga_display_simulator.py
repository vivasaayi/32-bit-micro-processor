#!/usr/bin/env python3
"""
VGA Display Simulator for RISC Processor
Converts VGA signals from simulation to viewable images on Mac
"""

import sys
import struct
import numpy as np
from PIL import Image, ImageDraw, ImageFont
import matplotlib.pyplot as plt
import matplotlib.animation as animation
from matplotlib.patches import Rectangle

class VGADisplaySimulator:
    def __init__(self):
        # VGA 640x480 @ 60Hz timing
        self.width = 640
        self.height = 480
        self.text_cols = 80
        self.text_rows = 25
        
        # Color palette (VGA-style 16 colors)
        self.colors = [
            (0, 0, 0),       # Black
            (0, 0, 170),     # Blue  
            (0, 170, 0),     # Green
            (0, 170, 170),   # Cyan
            (170, 0, 0),     # Red
            (170, 0, 170),   # Magenta
            (170, 85, 0),    # Brown
            (170, 170, 170), # Light Gray
            (85, 85, 85),    # Dark Gray
            (85, 85, 255),   # Light Blue
            (85, 255, 85),   # Light Green
            (85, 255, 255),  # Light Cyan
            (255, 85, 85),   # Light Red
            (255, 85, 255),  # Light Magenta
            (255, 255, 85),  # Yellow
            (255, 255, 255)  # White
        ]
        
        # Initialize display buffers
        self.text_buffer = [[' ' for _ in range(80)] for _ in range(25)]
        self.text_colors = [[(7, 0) for _ in range(80)] for _ in range(25)]  # (fg, bg)
        self.graphics_buffer = np.zeros((480, 640), dtype=np.uint8)
        self.display_mode = 0  # 0=text, 1=graphics, 2=mixed
        
    def load_text_buffer_from_hex(self, hex_data):
        """Load text buffer from memory dump"""
        # Simulate reading from 0xFF001000 (text buffer)
        for i, value in enumerate(hex_data):
            if i >= 80 * 25:
                break
            row = i // 80
            col = i % 80
            char = value & 0xFF
            attr = (value >> 8) & 0xFF
            fg = attr & 0x0F
            bg = (attr >> 4) & 0x0F
            
            self.text_buffer[row][col] = chr(char) if 32 <= char <= 126 else ' '
            self.text_colors[row][col] = (fg, bg)
    
    def load_graphics_buffer_from_hex(self, hex_data):
        """Load graphics buffer from memory dump"""
        # Simulate reading from 0xFF002000 (graphics buffer)
        for i, pixel in enumerate(hex_data):
            if i >= 640 * 480:
                break
            y = i // 640
            x = i % 640
            self.graphics_buffer[y, x] = pixel & 0xFF
    
    def render_text_mode(self):
        """Render text mode display"""
        img = Image.new('RGB', (640, 480), self.colors[0])
        draw = ImageDraw.Draw(img)
        
        # Try to use a monospace font
        try:
            font = ImageFont.truetype('/System/Library/Fonts/Monaco.ttf', 16)
        except:
            font = ImageFont.load_default()
        
        char_width = 8
        char_height = 19
        
        for row in range(25):
            for col in range(80):
                char = self.text_buffer[row][col]
                fg_color, bg_color = self.text_colors[row][col]
                
                x = col * char_width
                y = row * char_height
                
                # Draw background
                draw.rectangle([x, y, x + char_width, y + char_height], 
                             fill=self.colors[bg_color])
                
                # Draw character
                if char != ' ':
                    draw.text((x, y), char, fill=self.colors[fg_color], font=font)
        
        return img
    
    def render_graphics_mode(self):
        """Render graphics mode display"""
        img_array = np.zeros((480, 640, 3), dtype=np.uint8)
        
        for y in range(480):
            for x in range(640):
                color_index = self.graphics_buffer[y, x] % 16
                img_array[y, x] = self.colors[color_index]
        
        return Image.fromarray(img_array)
    
    def render_mixed_mode(self):
        """Render mixed mode (graphics + text overlay)"""
        # Start with graphics
        img = self.render_graphics_mode()
        draw = ImageDraw.Draw(img)
        
        try:
            font = ImageFont.truetype('/System/Library/Fonts/Monaco.ttf', 16)
        except:
            font = ImageFont.load_default()
        
        char_width = 8
        char_height = 19
        
        # Overlay text where there are non-space characters
        for row in range(25):
            for col in range(80):
                char = self.text_buffer[row][col]
                if char != ' ':
                    fg_color, bg_color = self.text_colors[row][col]
                    
                    x = col * char_width
                    y = row * char_height
                    
                    # Draw semi-transparent background for text
                    if bg_color != 0:  # If not transparent black
                        draw.rectangle([x, y, x + char_width, y + char_height], 
                                     fill=self.colors[bg_color])
                    
                    # Draw character
                    draw.text((x, y), char, fill=self.colors[fg_color], font=font)
        
        return img

def simulate_display_from_demo():
    """Simulate the display based on our demo program"""
    sim = VGADisplaySimulator()
    
    print("🎮 VGA Display Simulator")
    print("Simulating RISC processor display output...")
    
    # Simulate the demo program execution
    # 1. Text mode with "HELLO DISPLAY"
    print("\n📺 Text Mode Demo:")
    
    # Simulate writing "HELLO" at position 0
    hello_text = "HELLO"
    for i, char in enumerate(hello_text):
        sim.text_buffer[0][i] = char
        sim.text_colors[0][i] = (15, 0)  # White on black
    
    # Simulate writing "DISPLAY" at line 2 (80*1 offset)
    display_text = "DISPLAY"
    for i, char in enumerate(display_text):
        sim.text_buffer[1][i] = char
        sim.text_colors[1][i] = (10, 0)  # Light green on black
    
    # Add some CLI-style output
    cli_lines = [
        "=== RISC Processor Display System ===",
        "Interactive CLI Demo",
        "",
        "1. Text Mode Features:",
        "   * Colored text support",
        "   * Multiple colors available", 
        "   * Easy color switching",
        "",
        "2. Cursor Control:",
        "          This text is indented!",
        "   Back to normal position",
        "",
        "3. Switching to Graphics Mode...",
    ]
    
    for line_num, line in enumerate(cli_lines):
        if line_num >= 25:
            break
        for col, char in enumerate(line):
            if col >= 80:
                break
            sim.text_buffer[line_num][col] = char
            if "===" in line:
                sim.text_colors[line_num][col] = (14, 1)  # Yellow on blue
            elif line.startswith("   *") or line.startswith("   B"):
                sim.text_colors[line_num][col] = (15, 0)  # White on black
            elif line.startswith("1.") or line.startswith("2.") or line.startswith("3."):
                sim.text_colors[line_num][col] = (10, 0)  # Light green
            elif "indented" in line:
                sim.text_colors[line_num][col] = (11, 0)  # Light cyan
            else:
                sim.text_colors[line_num][col] = (7, 0)   # Light gray
    
    # Render and save text mode
    sim.display_mode = 0
    text_img = sim.render_text_mode()
    text_img.save('display_text_mode.png')
    print("   ✓ Saved: display_text_mode.png")
    
    # 2. Graphics mode simulation
    print("\n🖼️  Graphics Mode Demo:")
    
    # Simulate the pattern drawing from our demo
    for y in range(50, 200):
        for x in range(100, 300):
            color = ((x + y) // 8) % 16
            sim.graphics_buffer[y, x] = color
    
    # Draw some rectangles (like in our demo)
    # Red rectangle
    for y in range(50, 130):
        for x in range(50, 150):
            sim.graphics_buffer[y, x] = 4  # Red
    
    # Green rectangle  
    for y in range(100, 220):
        for x in range(200, 350):
            sim.graphics_buffer[y, x] = 2  # Green
    
    # Yellow rectangle
    for y in range(80, 180):
        for x in range(400, 520):
            sim.graphics_buffer[y, x] = 14  # Yellow
    
    # White border
    for x in range(640):
        sim.graphics_buffer[0, x] = 15      # Top
        sim.graphics_buffer[479, x] = 15    # Bottom
    for y in range(480):
        sim.graphics_buffer[y, 0] = 15      # Left  
        sim.graphics_buffer[y, 639] = 15    # Right
    
    # Render and save graphics mode
    sim.display_mode = 1
    graphics_img = sim.render_graphics_mode()
    graphics_img.save('display_graphics_mode.png')
    print("   ✓ Saved: display_graphics_mode.png")
    
    # 3. Mixed mode
    print("\n🔀 Mixed Mode Demo:")
    
    # Clear some text and add overlay text
    for row in range(25):
        for col in range(80):
            sim.text_buffer[row][col] = ' '
    
    # Add overlay text
    overlay_lines = [
        "",
        "",
        "",
        "",
        "",
        "                          MIXED MODE ACTIVE",
        "                        Text over graphics",
        "",
        "",
        "    Status: Graphics background with text overlay",
        "    Mode: Mixed rendering",
        "    Colors: Full palette available",
    ]
    
    for line_num, line in enumerate(overlay_lines):
        for col, char in enumerate(line):
            if col >= 80:
                break
            sim.text_buffer[line_num][col] = char
            if "MIXED MODE" in line:
                sim.text_colors[line_num][col] = (15, 0)  # Bright white
            elif "Text over" in line:
                sim.text_colors[line_num][col] = (14, 0)  # Yellow
            else:
                sim.text_colors[line_num][col] = (11, 0)  # Light cyan
    
    # Render and save mixed mode
    sim.display_mode = 2
    mixed_img = sim.render_mixed_mode()
    mixed_img.save('display_mixed_mode.png')
    print("   ✓ Saved: display_mixed_mode.png")
    
    return sim

def create_display_viewer():
    """Create an interactive display viewer"""
    print("\n🎯 Creating Interactive Viewer...")
    
    # Create a figure showing all three modes
    fig, axes = plt.subplots(1, 3, figsize=(18, 6))
    fig.suptitle('RISC Processor Display System Output', fontsize=16, fontweight='bold')
    
    # Load the generated images
    try:
        text_img = Image.open('display_text_mode.png')
        graphics_img = Image.open('display_graphics_mode.png') 
        mixed_img = Image.open('display_mixed_mode.png')
        
        axes[0].imshow(text_img)
        axes[0].set_title('Text Mode (CLI)', fontsize=12, fontweight='bold')
        axes[0].set_xlabel('80×25 characters, 16 colors')
        axes[0].axis('off')
        
        axes[1].imshow(graphics_img)
        axes[1].set_title('Graphics Mode', fontsize=12, fontweight='bold') 
        axes[1].set_xlabel('640×480 pixels, 256 colors')
        axes[1].axis('off')
        
        axes[2].imshow(mixed_img)
        axes[2].set_title('Mixed Mode', fontsize=12, fontweight='bold')
        axes[2].set_xlabel('Graphics + Text Overlay')
        axes[2].axis('off')
        
        plt.tight_layout()
        plt.savefig('display_system_showcase.png', dpi=150, bbox_inches='tight')
        plt.show()
        
        print("   ✓ Interactive viewer opened!")
        print("   ✓ Saved: display_system_showcase.png")
        
    except Exception as e:
        print(f"   ⚠️  Could not open viewer: {e}")
        print("   💡 You can manually open the PNG files")

if __name__ == "__main__":
    print("🚀 Starting VGA Display Simulation...")
    
    # Run the simulation
    simulator = simulate_display_from_demo()
    
    # Create viewer
    create_display_viewer()
    
    print("\n🎉 Display Simulation Complete!")
    print("\nGenerated files:")
    print("  📸 display_text_mode.png - Text/CLI mode output")
    print("  📸 display_graphics_mode.png - Graphics mode output") 
    print("  📸 display_mixed_mode.png - Mixed mode output")
    print("  📸 display_system_showcase.png - All modes combined")
    print("\n💡 Open these files to see your RISC processor's display!")
