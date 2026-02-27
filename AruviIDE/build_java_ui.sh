#!/bin/bash

# Build and Run RISC Processor Java UI
# This script compiles and runs the framebuffer viewer

set -e

JAVA_UI_DIR="java_ui"
JAVA_FILE="SimpleFramebufferViewer.java"
CLASS_FILE="SimpleFramebufferViewer.class"

echo "Building RISC Processor Java UI..."

# Check if Java is installed
if ! command -v javac &> /dev/null; then
    echo "Error: Java compiler (javac) not found. Please install Java JDK."
    exit 1
fi

# Create output directories
mkdir -p ../temp/reports

# Compile the Java UI
echo "Compiling Java UI..."
# cd $JAVA_UI_DIR
if javac $JAVA_FILE; then
    echo "✓ Java UI compiled successfully"
else
    echo "✗ Java compilation failed"
    exit 1
fi

# Run the UI
echo "Starting Framebuffer Viewer..."
echo "The viewer will watch for framebuffer files in: temp/reports/framebuffer.ppm"
echo "Close the window to exit."

java SimpleFramebufferViewer

echo "Java UI session ended."
