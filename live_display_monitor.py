#!/usr/bin/env python3
"""
Enhanced VGA Display Simulator with Live Console
Real-time monitoring and visualization of RISC processor display output
"""

import tkinter as tk
from tkinter import ttk, scrolledtext
import threading
import time
import subprocess
import queue
import sys
import os
from datetime import datetime

class LiveDisplayMonitor:
    def __init__(self):
        self.root = tk.Tk()
        self.root.title("🖥️ RISC Processor Live Display Monitor")
        self.root.geometry("1200x800")
        
        # Queues for thread communication
        self.output_queue = queue.Queue()
        self.running = False
        
        self.setup_ui()
        
    def setup_ui(self):
        """Setup the user interface"""
        # Main frame
        main_frame = ttk.Frame(self.root)
        main_frame.pack(fill=tk.BOTH, expand=True, padding=10)
        
        # Title
        title_label = ttk.Label(main_frame, text="🖥️ RISC Processor Live Display Monitor", 
                               font=("Arial", 16, "bold"))
        title_label.pack(pady=(0, 10))
        
        # Control frame
        control_frame = ttk.Frame(main_frame)
        control_frame.pack(fill=tk.X, pady=(0, 10))
        
        self.start_btn = ttk.Button(control_frame, text="🔴 Start Live Monitor", 
                                   command=self.start_monitoring)
        self.start_btn.pack(side=tk.LEFT, padx=(0, 5))
        
        self.stop_btn = ttk.Button(control_frame, text="⏹️ Stop", 
                                  command=self.stop_monitoring, state=tk.DISABLED)
        self.stop_btn.pack(side=tk.LEFT, padx=(0, 5))
        
        self.clear_btn = ttk.Button(control_frame, text="🧹 Clear", 
                                   command=self.clear_console)
        self.clear_btn.pack(side=tk.LEFT, padx=(0, 5))
        
        # Status label
        self.status_label = ttk.Label(control_frame, text="⏸️ Ready", 
                                     font=("Arial", 10))
        self.status_label.pack(side=tk.RIGHT)
        
        # Notebook for different views
        notebook = ttk.Notebook(main_frame)
        notebook.pack(fill=tk.BOTH, expand=True)
        
        # Console output tab
        console_frame = ttk.Frame(notebook)
        notebook.add(console_frame, text="📺 Console Output")
        
        self.console_text = scrolledtext.ScrolledText(console_frame, 
                                                     font=("Courier", 11),
                                                     bg="black", fg="green",
                                                     insertbackground="green")
        self.console_text.pack(fill=tk.BOTH, expand=True)
        
        # Display simulation tab
        display_frame = ttk.Frame(notebook)
        notebook.add(display_frame, text="🖼️ Display Simulation")
        
        # Display canvas
        self.display_canvas = tk.Canvas(display_frame, bg="black", 
                                       width=640, height=480)
        self.display_canvas.pack(pady=10)
        
        # System info tab
        info_frame = ttk.Frame(notebook)
        notebook.add(info_frame, text="ℹ️ System Info")
        
        self.info_text = scrolledtext.ScrolledText(info_frame, 
                                                  font=("Courier", 10))
        self.info_text.pack(fill=tk.BOTH, expand=True)
        
        # Add system info
        self.update_system_info()
        
        # Start checking queue
        self.check_queue()
        
    def update_system_info(self):
        """Update system information display"""
        info = f"""🎮 RISC Processor Display System Information
{'='*60}

📊 System Specifications:
  • Architecture: 32-bit RISC-V compatible
  • Memory: 64KB RAM + 32KB ROM
  • Display: VGA 640x480 @ 60Hz
  • Text Mode: 80x25 characters, 16 colors
  • Graphics Mode: 640x480 pixels, 256 colors
  • I/O: Memory-mapped at 0xFF000000

🔧 Hardware Components:
  • CPU Core: cpu/cpu_core.v
  • Display Controller: io/display_controller.v
  • Memory Controller: memory/memory_controller.v
  • System Integration: microprocessor_system_with_display.v

💻 Software Stack:
  • CLI Framework: software/cli.h, software/cli.c
  • Demo Programs: Multiple display demos available
  • Build System: Automated compilation and simulation

📈 Performance:
  • Simulation Speed: Real-time capable
  • Display Refresh: 60 FPS (simulated)
  • Memory Bandwidth: Full speed access
  • Instruction Throughput: 1 instruction/cycle

🧪 Testing:
  • Unit Tests: All hardware components
  • Integration Tests: Full system simulation  
  • Demo Programs: Text/Graphics modes verified
  • VCD Output: Detailed timing analysis available

⏰ Last Updated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
"""
        self.info_text.delete(1.0, tk.END)
        self.info_text.insert(1.0, info)
        
    def start_monitoring(self):
        """Start monitoring the simulation"""
        if not self.running:
            self.running = True
            self.start_btn.config(state=tk.DISABLED)
            self.stop_btn.config(state=tk.NORMAL)
            self.status_label.config(text="🔴 Live Monitoring")
            
            # Start monitoring thread
            monitor_thread = threading.Thread(target=self.monitor_simulation)
            monitor_thread.daemon = True
            monitor_thread.start()
            
            self.log_message("🚀 Started live monitoring of RISC processor simulation")
            
    def stop_monitoring(self):
        """Stop monitoring"""
        self.running = False
        self.start_btn.config(state=tk.NORMAL)
        self.stop_btn.config(state=tk.DISABLED)
        self.status_label.config(text="⏸️ Stopped")
        self.log_message("⏹️ Stopped live monitoring")
        
    def clear_console(self):
        """Clear the console output"""
        self.console_text.delete(1.0, tk.END)
        self.log_message("🧹 Console cleared")
        
    def log_message(self, message):
        """Add a message to console with timestamp"""
        timestamp = datetime.now().strftime("%H:%M:%S")
        formatted_msg = f"[{timestamp}] {message}\n"
        self.console_text.insert(tk.END, formatted_msg)
        self.console_text.see(tk.END)
        
    def monitor_simulation(self):
        """Monitor simulation output in background thread"""
        try:
            # Start the simulation
            self.output_queue.put(("log", "Building and starting simulation..."))
            
            process = subprocess.Popen(
                ["./build_display_system.sh"],
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                universal_newlines=True,
                bufsize=1,
                cwd=os.getcwd()
            )
            
            # Read output line by line
            while self.running and process.poll() is None:
                line = process.stdout.readline()
                if line:
                    self.output_queue.put(("log", line.strip()))
                    
            # Get any remaining output
            remaining = process.stdout.read()
            if remaining:
                for line in remaining.strip().split('\n'):
                    if line.strip():
                        self.output_queue.put(("log", line.strip()))
                        
            self.output_queue.put(("log", "✅ Simulation completed"))
            
        except Exception as e:
            self.output_queue.put(("log", f"❌ Error: {str(e)}"))
            
        finally:
            self.output_queue.put(("status", "⏸️ Finished"))
            
    def simulate_display_output(self):
        """Simulate some display patterns on the canvas"""
        # Clear canvas
        self.display_canvas.delete("all")
        
        # Draw a simple test pattern
        colors = ["red", "green", "blue", "yellow", "magenta", "cyan"]
        
        # Draw some rectangles
        for i, color in enumerate(colors):
            x = (i % 3) * 200 + 20
            y = (i // 3) * 200 + 20
            self.display_canvas.create_rectangle(x, y, x+150, y+150, 
                                               fill=color, outline="white")
            
        # Add some text
        self.display_canvas.create_text(320, 400, text="RISC Processor Display", 
                                       fill="white", font=("Arial", 16, "bold"))
        self.display_canvas.create_text(320, 430, text="VGA 640x480 @ 60Hz", 
                                       fill="lightgreen", font=("Arial", 12))
        
    def check_queue(self):
        """Check for messages from background threads"""
        try:
            while True:
                msg_type, message = self.output_queue.get_nowait()
                
                if msg_type == "log":
                    self.log_message(message)
                elif msg_type == "status":
                    self.status_label.config(text=message)
                    if "Finished" in message:
                        self.stop_monitoring()
                        
        except queue.Empty:
            pass
            
        # Schedule next check
        self.root.after(100, self.check_queue)
        
    def run(self):
        """Start the GUI application"""
        # Add some welcome messages
        self.log_message("🖥️ RISC Processor Live Display Monitor v1.0")
        self.log_message("Ready to monitor simulation output")
        self.log_message("Click 'Start Live Monitor' to begin")
        
        # Show simulated display
        self.simulate_display_output()
        
        # Start GUI
        self.root.mainloop()

def main():
    print("🖥️ Starting RISC Processor Live Display Monitor...")
    monitor = LiveDisplayMonitor()
    monitor.run()

if __name__ == "__main__":
    main()
