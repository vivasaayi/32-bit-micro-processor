#!/bin/bash
# Demo script for FramebufferTab Live Animation

echo "FramebufferTab Live Animation Demo"
echo "=================================="
echo

echo "This demo will:"
echo "1. Start the CPU IDE"
echo "2. Generate live animations for the framebuffer"
echo

echo "Instructions:"
echo "1. Open the IDE and go to the Framebuffer tab"
echo "2. Click 'Live Monitor' to start real-time viewing"
echo "3. Try different refresh rates: Ultra (16ms), Fast (33ms), Normal (100ms)"
echo "4. Use the animation generator to create live content"
echo

echo "Starting CPU IDE..."
cd /Users/rajanpanneerselvam/work/hdl/java_ui

# Start IDE in background
java -cp ".:lib/*" main.CpuIDE &
IDE_PID=$!

echo "IDE started (PID: $IDE_PID)"
echo

echo "Available animations:"
echo "1. bouncing_ball - Colorful bouncing ball with physics"
echo "2. plasma        - Psychedelic plasma effect"
echo "3. mandelbrot    - Zooming Mandelbrot fractal"
echo

echo "To start an animation, run in another terminal:"
echo "  cd /Users/rajanpanneerselvam/work/hdl/java_ui"
echo "  python3 animation_generator.py bouncing_ball"
echo "  python3 animation_generator.py plasma"
echo "  python3 animation_generator.py mandelbrot"
echo

echo "Press any key to continue or Ctrl+C to exit..."
read -n 1 -s

echo
echo "Starting bouncing ball animation..."
python3 animation_generator.py bouncing_ball &
ANIM_PID=$!

echo "Animation started (PID: $ANIM_PID)"
echo
echo "Go to the Framebuffer tab in the IDE and click 'Live Monitor'"
echo "Try different refresh rates for smooth animation!"
echo
echo "Press any key to stop animation and exit..."
read -n 1 -s

echo
echo "Stopping animation and IDE..."
kill $ANIM_PID 2>/dev/null
kill $IDE_PID 2>/dev/null

echo "Demo complete!"
