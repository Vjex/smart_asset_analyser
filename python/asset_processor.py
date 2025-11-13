#!/usr/bin/env python3
"""
Asset Processor Service for Flutter Asset Analyser

Handles SVG rasterization and Lottie frame extraction.
"""

import sys
import json
import argparse
from pathlib import Path
from typing import List, Dict, Optional
import tempfile
import base64

try:
    from PIL import Image
    import cairosvg
    try:
        from lottie import objects
        from lottie.exporters import raster
        HAS_LOTTIE = True
    except ImportError:
        HAS_LOTTIE = False
except ImportError as e:
    print(f"Error: Missing required package. Install with: pip install -r requirements.txt", file=sys.stderr)
    print(f"Missing: {e}", file=sys.stderr)
    sys.exit(1)


class AssetProcessor:
    """Processes SVG and Lottie assets for embedding generation."""
    
    def __init__(self, output_size: int = 512):
        """
        Initialize processor.
        
        Args:
            output_size: Size for rasterized images (default: 512)
        """
        self.output_size = output_size
    
    def rasterize_svg(self, svg_path: str, output_path: Optional[str] = None) -> str:
        """
        Rasterize SVG to PNG image.
        
        Args:
            svg_path: Path to SVG file
            output_path: Optional output path (creates temp file if not provided)
            
        Returns:
            Path to rasterized image
        """
        if output_path is None:
            # Create temporary file
            temp_file = tempfile.NamedTemporaryFile(suffix='.png', delete=False)
            output_path = temp_file.name
            temp_file.close()
        
        try:
            # Use cairosvg to rasterize SVG
            cairosvg.svg2png(
                url=svg_path,
                write_to=output_path,
                output_width=self.output_size,
                output_height=self.output_size,
            )
            return output_path
        except Exception as e:
            raise ValueError(f"Failed to rasterize SVG {svg_path}: {e}")
    
    def extract_lottie_frames(
        self,
        lottie_path: str,
        frame_indices: Optional[List[int]] = None,
    ) -> List[str]:
        """
        Extract frames from Lottie animation.
        
        Args:
            lottie_path: Path to Lottie JSON file
            frame_indices: List of frame indices to extract (default: first, middle, last)
            
        Returns:
            List of paths to extracted frame images
        """
        if not HAS_LOTTIE:
            raise ImportError("lottie package not installed. Install with: pip install python-lottie")
        
        try:
            # Parse Lottie JSON
            with open(lottie_path, 'r') as f:
                lottie_data = json.load(f)
            
            # Get animation properties
            fps = lottie_data.get('fr', 30)  # frames per second
            in_point = lottie_data.get('ip', 0)  # in point (start frame)
            out_point = lottie_data.get('op', 0)  # out point (end frame)
            duration = out_point - in_point
            
            if duration <= 0:
                raise ValueError(f"Invalid Lottie duration: {duration}")
            
            # Determine frames to extract
            if frame_indices is None:
                # Extract first, middle, and last frame
                frame_indices = [
                    in_point,
                    in_point + duration // 2,
                    out_point - 1,
                ]
                # Remove duplicates
                frame_indices = list(dict.fromkeys(frame_indices))
            
            # Create Lottie animation object
            animation = objects.Animation.load(lottie_data)
            
            # Extract frames
            frame_paths = []
            temp_dir = tempfile.mkdtemp()
            
            for i, frame_idx in enumerate(frame_indices):
                if frame_idx < in_point or frame_idx >= out_point:
                    continue
                
                # Render frame
                frame_path = Path(temp_dir) / f"frame_{i}.png"
                raster.export_png(
                    animation,
                    frame_path,
                    frame=frame_idx,
                    width=self.output_size,
                    height=self.output_size,
                )
                
                frame_paths.append(str(frame_path))
            
            return frame_paths
            
        except Exception as e:
            raise ValueError(f"Failed to extract Lottie frames from {lottie_path}: {e}")


def main():
    """Command-line interface for asset processor."""
    parser = argparse.ArgumentParser(description="Asset Processor Service")
    parser.add_argument(
        "--size",
        type=int,
        default=512,
        help="Output image size (default: 512)"
    )
    parser.add_argument(
        "command",
        choices=["svg", "lottie"],
        help="Processing command"
    )
    parser.add_argument(
        "input_path",
        help="Input file path"
    )
    parser.add_argument(
        "--output",
        help="Output path (optional, uses temp file if not provided)"
    )
    parser.add_argument(
        "--frames",
        help="Comma-separated frame indices for Lottie (e.g., 0,30,60)"
    )
    
    args = parser.parse_args()
    
    processor = AssetProcessor(output_size=args.size)
    
    try:
        if args.command == "svg":
            output_path = processor.rasterize_svg(args.input_path, args.output)
            result = {
                "success": True,
                "input_path": args.input_path,
                "output_path": output_path,
            }
            print(json.dumps(result, indent=2))
            
        elif args.command == "lottie":
            frame_indices = None
            if args.frames:
                frame_indices = [int(x) for x in args.frames.split(',')]
            
            frame_paths = processor.extract_lottie_frames(
                args.input_path,
                frame_indices,
            )
            result = {
                "success": True,
                "input_path": args.input_path,
                "frame_paths": frame_paths,
                "frame_count": len(frame_paths),
            }
            print(json.dumps(result, indent=2))
            
    except Exception as e:
        result = {
            "success": False,
            "error": str(e),
        }
        print(json.dumps(result, indent=2))
        sys.exit(1)


if __name__ == "__main__":
    main()

