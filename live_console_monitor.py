#!/usr/bin/env python3
"""
Live Console Monitor for RISC Processor Display System
Provides real-time visualization of console output from the simulation
"""

import subprocess
import time
import os
import sys
import threading
from datetime import datetime
import signal

class LiveConsoleMonitor:
    def __init__(self):
        self.running = False
        self.console_buffer = []
        self.max_lines = 25  # Simulate 80x25 terminal
        self.max_cols = 80
        
    def clear_screen(self):
        """Clear the terminal screen"""
        os.system('clear')
        
    def format_console_line(self, line, line_num):
        """Format a console line with line numbers and colors"""
        # Truncate or pad to 80 characters
        formatted = line.ljust(self.max_cols)[:self.max_cols]
        return f"\033[32m{line_num:2d}\033[0m │ {formatted}"
    
    def display_console(self):
        """Display the current console buffer"""
        self.clear_screen()
        
        print("\033[1m" + "=" * 85)
        print("🖥️  RISC Processor Live Console Monitor")
        print(f"📺 Display: {self.max_cols}x{self.max_lines} | ⏰ {datetime.now().strftime('%H:%M:%S')}")
        print("=" * 85 + "\033[0m")
        print()
        
        # Display console buffer
        for i, line in enumerate(self.console_buffer[-self.max_lines:], 1):
            print(self.format_console_line(line, i))
            
        # Fill remaining lines
        for i in range(len(self.console_buffer), self.max_lines):
            print(f"\033[90m{i+1:2d}\033[0m │ " + " " * self.max_cols)
            
        print()
        print("\033[1m" + "─" * 85 + "\033[0m")
        print("📊 Status: \033[32mLIVE\033[0m | 🔄 Press Ctrl+C to stop")
        
    def run_simulation_with_monitor(self):
        """Run the simulation and monitor its output"""
        print("🚀 Starting RISC processor simulation with live console monitoring...")
        print("Building and running display system...")
        
        try:
            # Start the simulation
            process = subprocess.Popen(
                ["./build_display_system.sh"],
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                universal_newlines=True,
                bufsize=1
            )
            
            self.running = True
            
            # Monitor output in real-time
            while self.running and process.poll() is None:
                line = process.stdout.readline()
                if line:
                    clean_line = line.strip()
                    if clean_line:
                        self.console_buffer.append(clean_line)
                        self.display_console()
                        time.sleep(0.1)  # Small delay for readability
                        
            # Get any remaining output
            remaining_output = process.stdout.read()
            if remaining_output:
                for line in remaining_output.strip().split('\n'):
                    if line.strip():
                        self.console_buffer.append(line.strip())
                        
            self.display_console()
            
        except KeyboardInterrupt:
            print("\n\n🛑 Console monitoring stopped by user")
            self.running = False
            
        except Exception as e:
            print(f"\n❌ Error during simulation: {e}")
            
    def run_interactive_console(self):
        """Run an interactive console simulation"""
        print("🎮 Starting Interactive Console Mode...")
        
        # Simulate some console output
        demo_lines = [
            "RISC Processor Display System v1.0",
            "Initializing hardware components...",
            "✓ CPU Core loaded",
            "✓ Memory controller ready", 
            "✓ Display controller initialized",
            "✓ VGA timing configured (640x480@60Hz)",
            "",
            "Starting demo program...",
            "> Hello, World!",
            "> This is the RISC processor console",
            "> Text mode: 80x25 characters",
            "> Color support: 16 colors",
            "",
            "Running graphics test...",
            "> Switching to graphics mode",
            "> Drawing test pattern",
            "> Frame buffer updated",
            "",
            "System ready for user input:",
            "> _"
        ]
        
        self.console_buffer = []
        self.running = True
        
        try:
            for line in demo_lines:
                if not self.running:
                    break
                    
                self.console_buffer.append(line)
                self.display_console()
                time.sleep(0.5)  # Simulate real-time output
                
            # Keep displaying until interrupted
            while self.running:
                time.sleep(1)
                self.display_console()
                
        except KeyboardInterrupt:
            print("\n\n🛑 Interactive console stopped")
            self.running = False
            
    def run_graphics_mode_demo(self):
        """Run a graphics mode demonstration"""
        print("🖼️ Starting Graphics Mode Demo...")
        
        # Graphics mode console output simulation
        graphics_lines = [
            "RISC Processor Graphics Mode v1.0",
            "Switching to VGA graphics mode...",
            "✓ Frame buffer initialized (640×480)",
            "✓ Color palette loaded (256 colors)",
            "✓ VGA timing: 25.175 MHz pixel clock",
            "",
            "Drawing graphics primitives...",
            "> plot_pixel(100, 100, RED)",
            "> draw_line(0, 0, 639, 479, GREEN)", 
            "> draw_rectangle(200, 150, 400, 300, BLUE)",
            "> fill_circle(320, 240, 50, YELLOW)",
            "",
            "Rendering color bars...",
            "> Color 0: RED    (255, 0, 0)",
            "> Color 1: GREEN  (0, 255, 0)",
            "> Color 2: BLUE   (0, 0, 255)",
            "> Color 3: YELLOW (255, 255, 0)",
            "> Color 4: MAGENTA(255, 0, 255)",
            "> Color 5: CYAN   (0, 255, 255)",
            "> Color 6: WHITE  (255, 255, 255)",
            "> Color 7: BLACK  (0, 0, 0)",
            "",
            "Frame buffer updates:",
            "> Frame 0: Drawing test pattern...",
            "> Frame 1: Updating animation...",
            "> Frame 2: Rendering sprites...",
            "> Frame 3: Processing input...",
            "> Frame 4: Displaying UI elements...",
            "",
            "VGA output signals:",
            "> HSYNC: 31.46 kHz",
            "> VSYNC: 59.94 Hz", 
            "> RGB: Active",
            "> Blanking: Proper timing",
            "",
            "Graphics mode ready!",
            "> Resolution: 640×480",
            "> Refresh rate: 60 Hz",
            "> Memory usage: 900 KB",
            "> Status: ACTIVE",
            "> _"
        ]
        
        self.console_buffer = []
        self.running = True
        
        try:
            for line in graphics_lines:
                if not self.running:
                    break
                    
                self.console_buffer.append(line)
                self.display_console()
                
                # Vary delay for different types of output
                if line.startswith("> Frame"):
                    time.sleep(0.8)  # Frame updates slower
                elif line.startswith("> Color"):
                    time.sleep(0.3)  # Color info faster
                else:
                    time.sleep(0.6)  # Normal speed
                
            # Keep displaying until interrupted
            while self.running:
                time.sleep(1)
                self.display_console()
                
        except KeyboardInterrupt:
            print("\n\n🛑 Graphics mode demo stopped")
            self.running = False

def signal_handler(sig, frame):
    print("\n\n🛑 Stopping console monitor...")
    sys.exit(0)

def main():
    signal.signal(signal.SIGINT, signal_handler)
    
    monitor = LiveConsoleMonitor()
    
    print("🖥️  RISC Processor Live Console Monitor")
    print("="*50)
    print()
    print("Choose monitoring mode:")
    print("1. 🔴 Live Simulation Monitor (runs actual simulation)")
    print("2. 🎮 Interactive Demo Console (simulated output)")
    print("3. 📊 Static Console Viewer (view saved output)")
    print("4. 🖼️ Graphics Mode Demo (simulated graphics output)")
    print()
    
    try:
        choice = input("Enter choice (1-4): ").strip()
        
        if choice == "1":
            monitor.run_simulation_with_monitor()
        elif choice == "2":
            monitor.run_interactive_console()
        elif choice == "3":
            print("📊 Showing last simulation output...")
            # Show output from last simulation
            try:
                with open("output/last_simulation.log", "r") as f:
                    lines = f.readlines()
                    monitor.console_buffer = [line.strip() for line in lines[-25:]]
                    monitor.display_console()
            except FileNotFoundError:
                print("❌ No saved simulation output found. Run option 1 first.")
        elif choice == "4":
            monitor.run_graphics_mode_demo()
        else:
            print("❌ Invalid choice")
            
    except KeyboardInterrupt:
        print("\n👋 Goodbye!")

if __name__ == "__main__":
    main()
