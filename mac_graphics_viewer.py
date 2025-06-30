#!/usr/bin/env python3
"""
Mac-friendly Graphics Viewer for RISC Processor
Uses matplotlib for reliable graphics display on macOS
"""

import matplotlib.pyplot as plt
import matplotlib.patches as patches
from matplotlib.animation import FuncAnimation
import numpy as np
import time
import subprocess
import os
from datetime import datetime

class MacGraphicsViewer:
    def __init__(self):
        # Graphics parameters
        self.width = 320
        self.height = 240
        self.frame_count = 0
        
        # Setup matplotlib with Mac backend
        plt.ion()  # Interactive mode
        self.fig, self.ax = plt.subplots(figsize=(10, 8))
        self.fig.suptitle('🖼️ RISC Processor Graphics Display', fontsize=16, fontweight='bold')
        
        # Create display area
        self.ax.set_xlim(0, self.width)
        self.ax.set_ylim(0, self.height)
        self.ax.set_aspect('equal')
        self.ax.set_title('VGA Display Output (320x240)', pad=20)
        self.ax.set_xlabel('X Coordinate')
        self.ax.set_ylabel('Y Coordinate')
        
        # Add grid
        self.ax.grid(True, alpha=0.3)
        
    def create_demo_pattern(self, pattern_type="color_bars"):
        """Create different demo patterns"""
        self.ax.clear()
        self.ax.set_xlim(0, self.width)
        self.ax.set_ylim(0, self.height)
        self.ax.set_title(f'Demo Pattern: {pattern_type.title().replace("_", " ")}', pad=20)
        self.ax.grid(True, alpha=0.3)
        
        if pattern_type == "color_bars":
            # Create color bars
            colors = ['red', 'green', 'blue', 'yellow', 'magenta', 'cyan', 'white', 'gray']
            bar_width = self.width // len(colors)
            
            for i, color in enumerate(colors):
                rect = patches.Rectangle((i * bar_width, 0), bar_width, self.height, 
                                       facecolor=color, alpha=0.7)
                self.ax.add_patch(rect)
                
        elif pattern_type == "checkerboard":
            # Create checkerboard pattern
            square_size = 20
            for x in range(0, self.width, square_size):
                for y in range(0, self.height, square_size):
                    if (x // square_size + y // square_size) % 2 == 0:
                        rect = patches.Rectangle((x, y), square_size, square_size, 
                                               facecolor='black', alpha=0.8)
                        self.ax.add_patch(rect)
                        
        elif pattern_type == "gradient":
            # Create gradient pattern
            for x in range(0, self.width, 4):
                intensity = x / self.width
                color = (intensity, 0.5, 1-intensity)
                rect = patches.Rectangle((x, 0), 4, self.height, 
                                       facecolor=color, alpha=0.8)
                self.ax.add_patch(rect)
                
        elif pattern_type == "circles":
            # Create circle pattern
            for i in range(5):
                for j in range(4):
                    x = (i + 0.5) * self.width / 5
                    y = (j + 0.5) * self.height / 4
                    radius = min(self.width / 12, self.height / 10)
                    color = plt.cm.rainbow(i / 5.0)
                    circle = patches.Circle((x, y), radius, facecolor=color, alpha=0.7)
                    self.ax.add_patch(circle)
                    
        elif pattern_type == "text_demo":
            # Create text display demo
            self.ax.text(self.width/2, self.height*0.8, 'RISC PROCESSOR', 
                        ha='center', va='center', fontsize=20, fontweight='bold', color='red')
            self.ax.text(self.width/2, self.height*0.6, 'Graphics Mode Active', 
                        ha='center', va='center', fontsize=16, color='blue')
            self.ax.text(self.width/2, self.height*0.4, f'Frame: {self.frame_count}', 
                        ha='center', va='center', fontsize=14, color='green')
            self.ax.text(self.width/2, self.height*0.2, datetime.now().strftime('%H:%M:%S'), 
                        ha='center', va='center', fontsize=12, color='purple')
                        
        # Add border
        border = patches.Rectangle((0, 0), self.width, self.height, 
                                 fill=False, edgecolor='black', linewidth=2)
        self.ax.add_patch(border)
        
        plt.draw()
        plt.pause(0.1)
        
    def run_demo_sequence(self):
        """Run a sequence of demo patterns"""
        patterns = ["color_bars", "checkerboard", "gradient", "circles", "text_demo"]
        
        print("🖼️ Starting Mac Graphics Viewer Demo...")
        print("Close the matplotlib window to exit.")
        
        try:
            for i in range(20):  # Run for 20 iterations
                pattern = patterns[i % len(patterns)]
                self.frame_count = i
                self.create_demo_pattern(pattern)
                time.sleep(2)  # Show each pattern for 2 seconds
                
                # Check if window is still open
                if not plt.get_fignums():
                    break
                    
        except KeyboardInterrupt:
            print("\\n⚠️ Demo interrupted by user")
        except Exception as e:
            print(f"⚠️ Error during demo: {e}")
            
        print("✅ Demo completed")
        
    def show_static_display(self, pattern="color_bars"):
        """Show a static display pattern"""
        print(f"🖼️ Showing static pattern: {pattern}")
        self.create_demo_pattern(pattern)
        
        print("Close the matplotlib window or press Ctrl+C to exit.")
        try:
            plt.show(block=True)
        except KeyboardInterrupt:
            print("\\n⚠️ Viewer closed by user")
            
    def analyze_vcd_graphics(self, vcd_file="testbench/system_with_display.vcd"):
        """Analyze VCD file for graphics data"""
        if not os.path.exists(vcd_file):
            print(f"⚠️ VCD file not found: {vcd_file}")
            return
            
        print(f"🔍 Analyzing VCD file: {vcd_file}")
        
        try:
            # Use grep to find VGA signals
            result = subprocess.run(['grep', '-E', '(hsync|vsync|rgb)', vcd_file], 
                                  capture_output=True, text=True)
            
            if result.stdout:
                lines = result.stdout.split('\\n')[:20]  # Show first 20 matches
                print(f"Found {len(lines)} VGA signal changes:")
                for line in lines:
                    if line.strip():
                        print(f"  {line.strip()}")
            else:
                print("No VGA signals found in VCD file")
                
        except Exception as e:
            print(f"⚠️ Error analyzing VCD: {e}")

def main():
    """Main function with command line options"""
    import sys
    
    viewer = MacGraphicsViewer()
    
    if len(sys.argv) > 1:
        command = sys.argv[1]
        
        if command == "demo":
            viewer.run_demo_sequence()
        elif command == "static":
            pattern = sys.argv[2] if len(sys.argv) > 2 else "color_bars"
            viewer.show_static_display(pattern)
        elif command == "analyze":
            vcd_file = sys.argv[2] if len(sys.argv) > 2 else "testbench/system_with_display.vcd"
            viewer.analyze_vcd_graphics(vcd_file)
        else:
            print(f"Unknown command: {command}")
            print("Usage: python3 mac_graphics_viewer.py [demo|static|analyze] [options]")
    else:
        # Default: show static color bars
        viewer.show_static_display("color_bars")

if __name__ == "__main__":
    main()
