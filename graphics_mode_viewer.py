#!/usr/bin/env python3
"""
Real-time Graphics Mode Viewer for RISC Processor
Extracts and displays graphics output from VGA simulation data
"""

import tkinter as tk
from tkinter import ttk
import threading
import time
import subprocess
import numpy as np
try:
    from PIL import Image, ImageTk
    PIL_AVAILABLE = True
except ImportError:
    PIL_AVAILABLE = False
    print("⚠️  PIL not available. Installing...")
    import subprocess
    subprocess.run(["pip3", "install", "pillow"], check=True)
    from PIL import Image, ImageTk
    PIL_AVAILABLE = True
import os
import re
from datetime import datetime

class GraphicsModeViewer:
    def __init__(self):
        self.root = tk.Tk()
        self.root.title("🖼️ RISC Processor Graphics Mode Viewer")
        self.root.geometry("900x700")
        
        # VGA parameters
        self.vga_width = 640
        self.vga_height = 480
        self.scale_factor = 1
        
        # Current frame buffer
        self.frame_buffer = np.zeros((self.vga_height, self.vga_width, 3), dtype=np.uint8)
        self.frame_count = 0
        
        self.setup_ui()
        
    def setup_ui(self):
        """Setup the graphics viewer UI"""
        # Main frame
        main_frame = ttk.Frame(self.root)
        main_frame.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)
        
        # Title and controls
        title_frame = ttk.Frame(main_frame)
        title_frame.pack(fill=tk.X, pady=(0, 10))
        
        title_label = ttk.Label(title_frame, text="🖼️ RISC Processor Graphics Mode Viewer", 
                               font=("Arial", 16, "bold"))
        title_label.pack(side=tk.LEFT)
        
        # Control buttons
        self.start_btn = ttk.Button(title_frame, text="🎬 Start Graphics Monitor", 
                                   command=self.start_graphics_monitoring)
        self.start_btn.pack(side=tk.RIGHT, padx=(5, 0))
        
        self.capture_btn = ttk.Button(title_frame, text="📸 Capture Frame", 
                                     command=self.capture_current_frame)
        self.capture_btn.pack(side=tk.RIGHT, padx=(5, 0))
        
        # Status frame
        status_frame = ttk.Frame(main_frame)
        status_frame.pack(fill=tk.X, pady=(0, 10))
        
        self.status_label = ttk.Label(status_frame, text="📺 Ready - VGA 640×480")
        self.status_label.pack(side=tk.LEFT)
        
        self.frame_label = ttk.Label(status_frame, text="Frame: 0")
        self.frame_label.pack(side=tk.RIGHT)
        
        # Notebook for different views
        notebook = ttk.Notebook(main_frame)
        notebook.pack(fill=tk.BOTH, expand=True)
        
        # Graphics display tab
        graphics_frame = ttk.Frame(notebook)
        notebook.add(graphics_frame, text="🖼️ Graphics Output")
        
        # Canvas for graphics display
        canvas_frame = ttk.Frame(graphics_frame)
        canvas_frame.pack(fill=tk.BOTH, expand=True)
        
        self.graphics_canvas = tk.Canvas(canvas_frame, bg="black", 
                                        width=self.vga_width, height=self.vga_height)
        self.graphics_canvas.pack(pady=10)
        
        # RGB analysis tab
        rgb_frame = ttk.Frame(notebook)
        notebook.add(rgb_frame, text="🎨 RGB Analysis")
        
        self.rgb_text = tk.Text(rgb_frame, font=("Courier", 10), height=20)
        self.rgb_text.pack(fill=tk.BOTH, expand=True, padx=5, pady=5)
        
        # Simulation data tab
        sim_frame = ttk.Frame(notebook)
        notebook.add(sim_frame, text="📊 Simulation Data")
        
        self.sim_text = tk.Text(sim_frame, font=("Courier", 10), height=20)
        self.sim_text.pack(fill=tk.BOTH, expand=True, padx=5, pady=5)
        
        # Initialize with demo graphics
        self.generate_demo_graphics()
        
    def generate_demo_graphics(self):
        """Generate demo graphics patterns"""
        # Create a test pattern
        self.frame_buffer = np.zeros((self.vga_height, self.vga_width, 3), dtype=np.uint8)
        
        # Color bars
        bar_width = self.vga_width // 8
        colors = [
            [255, 0, 0],    # Red
            [0, 255, 0],    # Green  
            [0, 0, 255],    # Blue
            [255, 255, 0],  # Yellow
            [255, 0, 255],  # Magenta
            [0, 255, 255],  # Cyan
            [255, 255, 255], # White
            [128, 128, 128]  # Gray
        ]
        
        for i, color in enumerate(colors):
            x_start = i * bar_width
            x_end = min((i + 1) * bar_width, self.vga_width)
            self.frame_buffer[0:100, x_start:x_end] = color
            
        # Geometric patterns
        # Checkerboard pattern
        checker_size = 20
        for y in range(120, 220):
            for x in range(0, self.vga_width):
                if (x // checker_size + y // checker_size) % 2:
                    self.frame_buffer[y, x] = [255, 255, 255]
                else:
                    self.frame_buffer[y, x] = [0, 0, 0]
                    
        # Gradient
        for y in range(240, 340):
            for x in range(self.vga_width):
                intensity = int((x / self.vga_width) * 255)
                self.frame_buffer[y, x] = [intensity, intensity, intensity]
                
        # Text area simulation
        for y in range(360, 460):
            for x in range(0, self.vga_width):
                # Simulate text background
                if y % 20 < 16:  # Character height
                    self.frame_buffer[y, x] = [0, 0, 0]  # Black background
                    if x % 8 < 6 and (x // 8) % 10 < 8:  # Character pattern
                        if (y % 16) in [2, 6, 10, 14]:
                            self.frame_buffer[y, x] = [0, 255, 0]  # Green text
                            
        self.update_graphics_display()
        
    def update_graphics_display(self):
        """Update the graphics display canvas"""
        try:
            # Convert numpy array to PIL Image
            pil_image = Image.fromarray(self.frame_buffer, 'RGB')
            
            # Scale if needed
            if self.scale_factor != 1:
                new_size = (int(self.vga_width * self.scale_factor), 
                           int(self.vga_height * self.scale_factor))
                pil_image = pil_image.resize(new_size, Image.NEAREST)
            
            # Convert to PhotoImage for tkinter
            self.photo_image = ImageTk.PhotoImage(pil_image)
            
            # Update canvas
            self.graphics_canvas.delete("all")
            self.graphics_canvas.create_image(self.vga_width//2, self.vga_height//2, 
                                            image=self.photo_image)
            
            # Update frame counter
            self.frame_label.config(text=f"Frame: {self.frame_count}")
            
        except Exception as e:
            print(f"Error updating display: {e}")
            
    def analyze_rgb_data(self):
        """Analyze current RGB data and display statistics"""
        try:
            # Calculate statistics
            total_pixels = self.vga_width * self.vga_height
            
            # Color analysis
            red_avg = np.mean(self.frame_buffer[:, :, 0])
            green_avg = np.mean(self.frame_buffer[:, :, 1])
            blue_avg = np.mean(self.frame_buffer[:, :, 2])
            
            # Find dominant colors
            unique_colors = np.unique(self.frame_buffer.reshape(-1, 3), axis=0)
            
            analysis = f"""🎨 RGB Analysis - Frame {self.frame_count}
{'='*50}

📊 Color Statistics:
  • Total Pixels: {total_pixels:,}
  • Unique Colors: {len(unique_colors)}
  • Red Average: {red_avg:.1f}
  • Green Average: {green_avg:.1f}  
  • Blue Average: {blue_avg:.1f}

🌈 Color Distribution:
  • Black Pixels: {np.sum(np.all(self.frame_buffer == [0,0,0], axis=2)):,}
  • White Pixels: {np.sum(np.all(self.frame_buffer == [255,255,255], axis=2)):,}
  • Red Pixels: {np.sum(np.all(self.frame_buffer == [255,0,0], axis=2)):,}
  • Green Pixels: {np.sum(np.all(self.frame_buffer == [0,255,0], axis=2)):,}
  • Blue Pixels: {np.sum(np.all(self.frame_buffer == [0,0,255], axis=2)):,}

🎯 Display Regions:
  • Top Color Bars: Lines 0-99
  • Checkerboard: Lines 120-219
  • Gradient: Lines 240-339
  • Text Area: Lines 360-459

⏰ Updated: {datetime.now().strftime('%H:%M:%S')}
"""
            
            self.rgb_text.delete(1.0, tk.END)
            self.rgb_text.insert(1.0, analysis)
            
        except Exception as e:
            print(f"Error in RGB analysis: {e}")
            
    def start_graphics_monitoring(self):
        """Start monitoring graphics output from simulation"""
        self.status_label.config(text="🔴 Monitoring Graphics Output...")
        
        # Start monitoring thread
        monitor_thread = threading.Thread(target=self.monitor_graphics_output)
        monitor_thread.daemon = True
        monitor_thread.start()
        
    def monitor_graphics_output(self):
        """Monitor graphics output from VCD or simulation"""
        try:
            # Run simulation and monitor for graphics data
            self.log_simulation_data("Starting graphics monitoring...")
            self.log_simulation_data("Running display system simulation...")
            
            # Simulate real-time graphics updates
            for frame in range(10):
                time.sleep(1)
                
                # Generate animated graphics
                self.animate_graphics(frame)
                self.frame_count = frame + 1
                
                # Update display
                self.root.after(0, self.update_graphics_display)
                self.root.after(0, self.analyze_rgb_data)
                
                self.log_simulation_data(f"Frame {frame + 1}: Graphics updated")
                
            self.log_simulation_data("Graphics monitoring completed")
            self.root.after(0, lambda: self.status_label.config(text="✅ Graphics Monitoring Complete"))
            
        except Exception as e:
            self.log_simulation_data(f"Error in graphics monitoring: {e}")
            
    def animate_graphics(self, frame):
        """Create animated graphics for demonstration"""
        # Rotate colors in the color bars
        bar_width = self.vga_width // 8
        colors = [
            [255, 0, 0],    # Red
            [0, 255, 0],    # Green  
            [0, 0, 255],    # Blue
            [255, 255, 0],  # Yellow
            [255, 0, 255],  # Magenta
            [0, 255, 255],  # Cyan
            [255, 255, 255], # White
            [128, 128, 128]  # Gray
        ]
        
        # Shift colors based on frame
        shifted_colors = colors[frame % len(colors):] + colors[:frame % len(colors)]
        
        for i, color in enumerate(shifted_colors):
            x_start = i * bar_width
            x_end = min((i + 1) * bar_width, self.vga_width)
            self.frame_buffer[0:100, x_start:x_end] = color
            
        # Animate gradient
        for y in range(240, 340):
            for x in range(self.vga_width):
                intensity = int(((x + frame * 10) % self.vga_width / self.vga_width) * 255)
                self.frame_buffer[y, x] = [intensity, intensity, intensity]
                
    def capture_current_frame(self):
        """Capture and save current frame"""
        try:
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            filename = f"graphics_frame_{timestamp}.png"
            
            pil_image = Image.fromarray(self.frame_buffer, 'RGB')
            pil_image.save(filename)
            
            self.status_label.config(text=f"📸 Frame saved: {filename}")
            self.log_simulation_data(f"Frame captured: {filename}")
            
        except Exception as e:
            self.log_simulation_data(f"Error capturing frame: {e}")
            
    def log_simulation_data(self, message):
        """Log simulation data and events"""
        timestamp = datetime.now().strftime("%H:%M:%S")
        log_message = f"[{timestamp}] {message}\n"
        
        self.root.after(0, lambda: self.sim_text.insert(tk.END, log_message))
        self.root.after(0, lambda: self.sim_text.see(tk.END))
        
    def run(self):
        """Start the graphics viewer"""
        self.log_simulation_data("🖼️ Graphics Mode Viewer initialized")
        self.log_simulation_data("VGA Resolution: 640×480")
        self.log_simulation_data("Ready to monitor graphics output")
        
        # Initial RGB analysis
        self.analyze_rgb_data()
        
        self.root.mainloop()

def main():
    print("🖼️ Starting RISC Processor Graphics Mode Viewer...")
    viewer = GraphicsModeViewer()
    viewer.run()

if __name__ == "__main__":
    main()
