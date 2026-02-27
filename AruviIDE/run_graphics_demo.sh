#!/bin/bash

# Animation demo for the Java UI
echo "Starting RISC CPU Graphics Animation Demo..."
echo "Make sure the Java UI is running and click 'Auto Refresh'"

frame=0
while [ $frame -lt 30 ]; do
    echo "Generating animation frame $frame..."
    python3 advanced_framebuffer_extractor.py "animation_$frame"
    sleep 0.5  # 2 FPS animation
    frame=$((frame + 1))
done

echo "Animation complete! The moving yellow rectangle should have been visible."
