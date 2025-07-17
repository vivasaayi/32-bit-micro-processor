#!/usr/bin/env python3
"""
Animation Creator for Bouncing Rectangle Simulation
Creates an animated GIF from individual framebuffer PPM files.
"""

import os
import glob
from PIL import Image
import argparse

def create_animation_from_ppm_files(input_dir, output_file, fps=10):
    """
    Create an animated GIF from numbered PPM files.
    
    Args:
        input_dir: Directory containing framebuffer_XXXX.ppm files
        output_file: Output GIF filename
        fps: Frames per second for the animation
    """
    
    # Find all framebuffer PPM files
    pattern = os.path.join(input_dir, "framebuffer_*.ppm")
    ppm_files = sorted(glob.glob(pattern))
    
    if not ppm_files:
        print(f"No framebuffer PPM files found in {input_dir}")
        print(f"Looking for pattern: {pattern}")
        return False
    
    print(f"Found {len(ppm_files)} framebuffer files")
    
    # Load images
    images = []
    for i, ppm_file in enumerate(ppm_files):
        try:
            img = Image.open(ppm_file)
            # Convert to RGB if necessary
            if img.mode != 'RGB':
                img = img.convert('RGB')
            images.append(img)
            print(f"Loaded frame {i+1}/{len(ppm_files)}: {os.path.basename(ppm_file)}")
        except Exception as e:
            print(f"Error loading {ppm_file}: {e}")
            continue
    
    if not images:
        print("No valid images loaded")
        return False
    
    # Calculate duration per frame in milliseconds
    duration = int(1000 / fps)
    
    # Create animated GIF
    print(f"Creating animation: {output_file}")
    print(f"Frames: {len(images)}, FPS: {fps}, Duration per frame: {duration}ms")
    
    try:
        images[0].save(
            output_file,
            save_all=True,
            append_images=images[1:],
            duration=duration,
            loop=0,  # Loop forever
            optimize=True
        )
        print(f"Animation created successfully: {output_file}")
        return True
    except Exception as e:
        print(f"Error creating animation: {e}")
        return False

def main():
    parser = argparse.ArgumentParser(description='Create animation from framebuffer dumps')
    parser.add_argument('--input-dir', '-i', 
                       default='/Users/rajanpanneerselvam/work/hdl/temp/reports',
                       help='Directory containing framebuffer PPM files')
    parser.add_argument('--output', '-o',
                       default='/Users/rajanpanneerselvam/work/hdl/bouncing_rectangle_animation.gif',
                       help='Output GIF filename')
    parser.add_argument('--fps', '-f', type=int, default=10,
                       help='Frames per second for animation')
    parser.add_argument('--list', '-l', action='store_true',
                       help='List available framebuffer files and exit')
    
    args = parser.parse_args()
    
    if args.list:
        pattern = os.path.join(args.input_dir, "framebuffer_*.ppm")
        ppm_files = sorted(glob.glob(pattern))
        print(f"Found {len(ppm_files)} framebuffer files in {args.input_dir}:")
        for f in ppm_files:
            print(f"  {os.path.basename(f)}")
        return
    
    # Create the animation
    success = create_animation_from_ppm_files(args.input_dir, args.output, args.fps)
    
    if success:
        print(f"\n✓ Animation complete!")
        print(f"  Input: {args.input_dir}")
        print(f"  Output: {args.output}")
        print(f"  FPS: {args.fps}")
        print(f"\nTo view the animation:")
        print(f"  open {args.output}")
    else:
        print(f"\n✗ Animation creation failed")

if __name__ == "__main__":
    main()
