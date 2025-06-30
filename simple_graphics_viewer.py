#!/usr/bin/env python3
"""
Simple Graphics Mode Viewer for RISC Processor
Basic graphics visualization without external dependencies
"""

import tkinter as tk
from tkinter import ttk, messagebox
import threading
import time
import subprocess
import os
import math
from datetime import datetime

class SimpleGraphicsViewer:
    def __init__(self):
        self.root = tk.Tk()
        self.root.title("🖼️ RISC Processor Graphics Viewer")
        self.root.geometry("800x600")
        
        # Graphics parameters
        self.canvas_width = 640
        self.canvas_height = 480
        self.scale = 0.8  # Scale down to fit in window
        
        self.frame_count = 0
        self.animation_running = False
        
        self.setup_ui()
        
    def setup_ui(self):
        """Setup the simple graphics viewer UI"""
        # Main container
        main_frame = ttk.Frame(self.root)
        main_frame.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)
        
        # Title and controls
        title_frame = ttk.Frame(main_frame)
        title_frame.pack(fill=tk.X, pady=(0, 10))
        
        title_label = ttk.Label(title_frame, text="🖼️ RISC Processor Graphics Mode", 
                               font=("Arial", 16, "bold"))
        title_label.pack(side=tk.LEFT)
        
        # Control buttons
        btn_frame = ttk.Frame(title_frame)
        btn_frame.pack(side=tk.RIGHT)
        
        self.start_btn = ttk.Button(btn_frame, text="🎬 Start Animation", 
                                   command=self.start_animation)
        self.start_btn.pack(side=tk.LEFT, padx=(0, 5))
        
        self.stop_btn = ttk.Button(btn_frame, text="⏹️ Stop", 
                                  command=self.stop_animation)
        self.stop_btn.pack(side=tk.LEFT, padx=(0, 5))
        
        self.capture_btn = ttk.Button(btn_frame, text="📸 Capture", 
                                     command=self.show_capture_info)
        self.capture_btn.pack(side=tk.LEFT)
        
        # Status frame
        status_frame = ttk.Frame(main_frame)
        status_frame.pack(fill=tk.X, pady=(0, 10))
        
        self.status_label = ttk.Label(status_frame, text="📺 VGA 640×480 - Ready")
        self.status_label.pack(side=tk.LEFT)
        
        self.frame_label = ttk.Label(status_frame, text="Frame: 0")
        self.frame_label.pack(side=tk.RIGHT)
        
        # Graphics canvas with scrollbars
        canvas_frame = ttk.Frame(main_frame)
        canvas_frame.pack(fill=tk.BOTH, expand=True)
        
        # Create canvas with scrollbars
        self.canvas = tk.Canvas(canvas_frame, 
                               width=int(self.canvas_width * self.scale),
                               height=int(self.canvas_height * self.scale),
                               bg="black", 
                               scrollregion=(0, 0, self.canvas_width, self.canvas_height))
        
        v_scrollbar = ttk.Scrollbar(canvas_frame, orient=tk.VERTICAL, command=self.canvas.yview)
        h_scrollbar = ttk.Scrollbar(canvas_frame, orient=tk.HORIZONTAL, command=self.canvas.xview)
        
        self.canvas.configure(yscrollcommand=v_scrollbar.set, xscrollcommand=h_scrollbar.set)
        
        # Pack scrollbars and canvas
        v_scrollbar.pack(side=tk.RIGHT, fill=tk.Y)
        h_scrollbar.pack(side=tk.BOTTOM, fill=tk.X)
        self.canvas.pack(side=tk.LEFT, fill=tk.BOTH, expand=True)
        
        # Info text area
        info_frame = ttk.LabelFrame(main_frame, text="🎨 Graphics Info")
        info_frame.pack(fill=tk.X, pady=(10, 0))
        
        self.info_text = tk.Text(info_frame, height=6, font=("Courier", 10))
        info_scroll = ttk.Scrollbar(info_frame, orient=tk.VERTICAL, command=self.info_text.yview)
        self.info_text.configure(yscrollcommand=info_scroll.set)
        
        info_scroll.pack(side=tk.RIGHT, fill=tk.Y)
        self.info_text.pack(side=tk.LEFT, fill=tk.BOTH, expand=True)
        
        # Generate initial graphics
        self.draw_initial_graphics()
        self.update_info()
        
    def draw_initial_graphics(self):
        """Draw initial graphics demonstration"""
        self.canvas.delete("all")
        
        # Scale factor for drawing
        s = self.scale
        
        # Draw color bars at top
        colors = ["red", "green", "blue", "yellow", "magenta", "cyan", "white", "gray"]
        bar_width = self.canvas_width // len(colors)
        
        for i, color in enumerate(colors):
            x1 = i * bar_width * s
            x2 = (i + 1) * bar_width * s
            y1 = 0
            y2 = 80 * s
            self.canvas.create_rectangle(x1, y1, x2, y2, fill=color, outline="")
            
        # Draw text area
        self.canvas.create_rectangle(0, 90*s, self.canvas_width*s, 180*s, 
                                   fill="black", outline="green")
        self.canvas.create_text(20*s, 100*s, anchor=tk.NW, 
                               text="RISC Processor Graphics Mode", 
                               fill="green", font=("Courier", int(12*s)))
        self.canvas.create_text(20*s, 120*s, anchor=tk.NW, 
                               text="VGA 640×480 @ 60Hz", 
                               fill="lightgreen", font=("Courier", int(10*s)))
        self.canvas.create_text(20*s, 140*s, anchor=tk.NW, 
                               text="Text + Graphics Mode", 
                               fill="cyan", font=("Courier", int(10*s)))
        
        # Draw geometric patterns
        self.draw_geometric_patterns()
        
        # Draw status indicators
        self.draw_status_indicators()
        
    def draw_geometric_patterns(self):
        """Draw geometric patterns"""
        s = self.scale
        
        # Checkerboard pattern
        checker_size = 20 * s
        start_y = 200 * s
        for y in range(int(start_y), int(start_y + 100*s), int(checker_size)):
            for x in range(0, int(self.canvas_width*s), int(checker_size)):
                if ((x//checker_size) + (y//checker_size)) % 2:
                    self.canvas.create_rectangle(x, y, x+checker_size, y+checker_size, 
                                               fill="white", outline="")
                    
        # Gradient bars
        gradient_y = 320 * s
        for x in range(0, int(self.canvas_width*s), 4):
            intensity = int((x / (self.canvas_width*s)) * 255)
            color = f"#{intensity:02x}{intensity:02x}{intensity:02x}"
            self.canvas.create_rectangle(x, gradient_y, x+4, gradient_y+40*s, 
                                       fill=color, outline="")
            
        # Moving sine wave (frame-dependent)
        self.draw_sine_wave()
        
    def draw_sine_wave(self):
        """Draw animated sine wave"""
        s = self.scale
        wave_y = 380 * s
        
        points = []
        for x in range(0, int(self.canvas_width*s), 2):
            # Add frame offset for animation
            angle = (x / (self.canvas_width*s)) * 4 * math.pi + (self.frame_count * 0.2)
            y = wave_y + math.sin(angle) * 30 * s
            points.extend([x, y])
            
        if len(points) >= 4:
            self.canvas.create_line(points, fill="yellow", width=2, smooth=True)
            
    def draw_status_indicators(self):
        """Draw system status indicators"""
        s = self.scale
        
        # CPU status
        self.canvas.create_oval(550*s, 20*s, 570*s, 40*s, fill="green", outline="")
        self.canvas.create_text(575*s, 30*s, anchor=tk.W, text="CPU", fill="white", 
                               font=("Arial", int(10*s)))
        
        # Display status
        self.canvas.create_oval(550*s, 50*s, 570*s, 70*s, fill="blue", outline="")
        self.canvas.create_text(575*s, 60*s, anchor=tk.W, text="VGA", fill="white", 
                               font=("Arial", int(10*s)))
        
        # Frame counter
        self.canvas.create_text(500*s, 100*s, anchor=tk.W, 
                               text=f"Frame: {self.frame_count}", 
                               fill="white", font=("Arial", int(12*s)))
        
    def start_animation(self):
        """Start the graphics animation"""
        if not self.animation_running:
            self.animation_running = True
            self.start_btn.config(state=tk.DISABLED)
            self.stop_btn.config(state=tk.NORMAL)
            self.status_label.config(text="🔴 Animation Running")
            
            # Start animation thread
            anim_thread = threading.Thread(target=self.animation_loop)
            anim_thread.daemon = True
            anim_thread.start()
            
    def stop_animation(self):
        """Stop the animation"""
        self.animation_running = False
        self.start_btn.config(state=tk.NORMAL)
        self.stop_btn.config(state=tk.DISABLED)
        self.status_label.config(text="⏸️ Animation Stopped")
        
    def animation_loop(self):
        """Main animation loop"""
        while self.animation_running:
            self.frame_count += 1
            
            # Update graphics on main thread
            self.root.after(0, self.update_frame)
            
            # Control animation speed
            time.sleep(1/30)  # ~30 FPS
            
    def update_frame(self):
        """Update graphics frame"""
        if self.animation_running:
            # Redraw graphics with new frame
            self.draw_initial_graphics()
            
            # Update frame counter display
            self.frame_label.config(text=f"Frame: {self.frame_count}")
            
            # Update info
            self.update_info()
            
    def update_info(self):
        """Update information display"""
        info = f"""🎨 Graphics Mode Information
{'='*40}

📺 Display Resolution: 640×480
🎯 Color Depth: 24-bit RGB
📊 Frame Rate: ~30 FPS (simulated)
🖼️  Current Frame: {self.frame_count}

🎮 Features Demonstrated:
• Color bars (8 colors)
• Text overlay on graphics
• Geometric patterns
• Animated sine wave
• System status indicators

⏰ Updated: {datetime.now().strftime('%H:%M:%S')}

💡 This simulates your RISC processor's
   VGA graphics output in real-time.
"""
        
        self.info_text.delete(1.0, tk.END)
        self.info_text.insert(1.0, info)
        
    def show_capture_info(self):
        """Show capture information"""
        messagebox.showinfo("📸 Frame Capture", 
                           f"Current frame: {self.frame_count}\n"
                           f"Resolution: {self.canvas_width}×{self.canvas_height}\n"
                           f"Status: {'Running' if self.animation_running else 'Stopped'}\n\n"
                           f"In a real implementation, this would\n"
                           f"save the current frame buffer to a file.")
        
    def run(self):
        """Start the graphics viewer"""
        self.root.mainloop()

def main():
    print("🖼️ Starting Simple Graphics Mode Viewer...")
    print("TK_SILENCE_DEPRECATION=1")  # Suppress Tk deprecation warning
    os.environ['TK_SILENCE_DEPRECATION'] = '1'
    
    viewer = SimpleGraphicsViewer()
    viewer.run()

if __name__ == "__main__":
    main()
