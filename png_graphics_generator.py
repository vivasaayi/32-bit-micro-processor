#!/usr/bin/env python3
"""
PNG Graphics Generator for RISC Processor
Creates static PNG images of graphics patterns without GUI dependencies
"""

import matplotlib.pyplot as plt
import matplotlib.patches as patches
import numpy as np
import os
from datetime import datetime

def create_graphics_png(pattern_type="color_bars", output_file=None, width=320, height=240):
    """Create a PNG image of a graphics pattern"""
    
    if output_file is None:
        output_file = f"graphics_{pattern_type}_{datetime.now().strftime('%Y%m%d_%H%M%S')}.png"
    
    # Use non-interactive backend for PNG generation
    plt.ioff()
    fig, ax = plt.subplots(figsize=(10, 8))
    fig.suptitle(f'🖼️ RISC Processor Graphics: {pattern_type.title().replace("_", " ")}', 
                 fontsize=16, fontweight='bold')
    
    # Setup display area
    ax.set_xlim(0, width)
    ax.set_ylim(0, height)
    ax.set_aspect('equal')
    ax.set_title(f'VGA Display Output ({width}x{height})', pad=20)
    ax.set_xlabel('X Coordinate')
    ax.set_ylabel('Y Coordinate')
    ax.grid(True, alpha=0.3)
    
    # Generate pattern
    if pattern_type == "color_bars":
        colors = ['red', 'green', 'blue', 'yellow', 'magenta', 'cyan', 'white', 'gray']
        bar_width = width // len(colors)
        
        for i, color in enumerate(colors):
            rect = patches.Rectangle((i * bar_width, 0), bar_width, height, 
                                   facecolor=color, alpha=0.7)
            ax.add_patch(rect)
            
    elif pattern_type == "checkerboard":
        square_size = 20
        for x in range(0, width, square_size):
            for y in range(0, height, square_size):
                if (x // square_size + y // square_size) % 2 == 0:
                    rect = patches.Rectangle((x, y), square_size, square_size, 
                                           facecolor='black', alpha=0.8)
                    ax.add_patch(rect)
                    
    elif pattern_type == "gradient":
        for x in range(0, width, 4):
            intensity = x / width
            color = (intensity, 0.5, 1-intensity)
            rect = patches.Rectangle((x, 0), 4, height, 
                                   facecolor=color, alpha=0.8)
            ax.add_patch(rect)
            
    elif pattern_type == "circles":
        for i in range(5):
            for j in range(4):
                x = (i + 0.5) * width / 5
                y = (j + 0.5) * height / 4
                radius = min(width / 12, height / 10)
                color = plt.cm.rainbow(i / 5.0)
                circle = patches.Circle((x, y), radius, facecolor=color, alpha=0.7)
                ax.add_patch(circle)
                
    elif pattern_type == "test_pattern":
        # Comprehensive test pattern
        # Vertical lines
        for x in range(0, width, 40):
            ax.axvline(x, color='red', alpha=0.5, linewidth=2)
        
        # Horizontal lines  
        for y in range(0, height, 30):
            ax.axhline(y, color='blue', alpha=0.5, linewidth=2)
            
        # Corner markers
        corner_size = 20
        corners = [(0, 0), (width-corner_size, 0), (0, height-corner_size), (width-corner_size, height-corner_size)]
        for x, y in corners:
            rect = patches.Rectangle((x, y), corner_size, corner_size, 
                                   facecolor='yellow', alpha=0.8)
            ax.add_patch(rect)
            
        # Center circle
        center_x, center_y = width // 2, height // 2
        circle = patches.Circle((center_x, center_y), 50, facecolor='green', alpha=0.6)
        ax.add_patch(circle)
        
    elif pattern_type == "text_demo":
        ax.text(width/2, height*0.8, 'RISC PROCESSOR', 
                ha='center', va='center', fontsize=20, fontweight='bold', color='red')
        ax.text(width/2, height*0.6, 'Graphics Mode Active', 
                ha='center', va='center', fontsize=16, color='blue')
        ax.text(width/2, height*0.4, 'PNG Output Mode', 
                ha='center', va='center', fontsize=14, color='green')
        ax.text(width/2, height*0.2, datetime.now().strftime('%Y-%m-%d %H:%M:%S'), 
                ha='center', va='center', fontsize=12, color='purple')
    
    # Add border
    border = patches.Rectangle((0, 0), width, height, 
                             fill=False, edgecolor='black', linewidth=3)
    ax.add_patch(border)
    
    # Save as PNG
    plt.savefig(output_file, dpi=150, bbox_inches='tight', 
                facecolor='white', edgecolor='none')
    plt.close()
    
    return output_file

def generate_all_patterns():
    """Generate PNG images for all available patterns"""
    patterns = ["color_bars", "checkerboard", "gradient", "circles", "test_pattern", "text_demo"]
    output_files = []
    
    print("🖼️ Generating PNG graphics patterns...")
    
    for pattern in patterns:
        try:
            output_file = create_graphics_png(pattern)
            output_files.append(output_file)
            print(f"✅ Created: {output_file}")
        except Exception as e:
            print(f"⚠️ Error creating {pattern}: {e}")
    
    return output_files

def main():
    """Main function with command line options"""
    import sys
    
    if len(sys.argv) > 1:
        command = sys.argv[1]
        
        if command == "all":
            files = generate_all_patterns()
            print(f"\\n🎉 Generated {len(files)} PNG files:")
            for file in files:
                print(f"  {file}")
                
        elif command in ["color_bars", "checkerboard", "gradient", "circles", "test_pattern", "text_demo"]:
            output_file = sys.argv[2] if len(sys.argv) > 2 else None
            file = create_graphics_png(command, output_file)
            print(f"✅ Created: {file}")
            
        else:
            print(f"Unknown pattern: {command}")
            print("Available patterns: color_bars, checkerboard, gradient, circles, test_pattern, text_demo")
            print("Use 'all' to generate all patterns")
    else:
        # Default: generate all patterns
        files = generate_all_patterns()
        print(f"\\n🎉 Generated {len(files)} PNG files")

if __name__ == "__main__":
    main()
