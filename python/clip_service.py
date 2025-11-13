#!/usr/bin/env python3
"""
CLIP Embedding Service for Flutter Asset Analyser

This service generates visual embeddings using CLIP model.
Can be called via command line or HTTP API.
"""

import sys
import json
import argparse
from pathlib import Path
from typing import List, Dict, Optional
import base64
from io import BytesIO

try:
    import torch
    import clip
    from PIL import Image
    import numpy as np
except ImportError as e:
    print(f"Error: Missing required package. Install with: pip install -r requirements.txt", file=sys.stderr)
    print(f"Missing: {e}", file=sys.stderr)
    sys.exit(1)


class CLIPEmbeddingService:
    """Service for generating CLIP embeddings from images."""
    
    def __init__(self, model_name: str = "ViT-B/32", device: Optional[str] = None):
        """
        Initialize CLIP model.
        
        Args:
            model_name: CLIP model name (ViT-B/32, ViT-L/14, etc.)
            device: Device to run on ('cuda', 'cpu', or None for auto)
        """
        self.model_name = model_name
        self.device = device or ("cuda" if torch.cuda.is_available() else "cpu")
        
        print(f"Loading CLIP model: {model_name} on {self.device}...", file=sys.stderr)
        try:
            self.model, self.preprocess = clip.load(model_name, device=self.device)
            self.model.eval()
            print(f"Model loaded successfully!", file=sys.stderr)
        except Exception as e:
            print(f"Error loading CLIP model: {e}", file=sys.stderr)
            sys.exit(1)
    
    def load_image(self, image_path: str) -> Image.Image:
        """Load and preprocess image."""
        try:
            image = Image.open(image_path).convert("RGB")
            return image
        except Exception as e:
            raise ValueError(f"Failed to load image {image_path}: {e}")
    
    def generate_embedding(self, image_path: str) -> List[float]:
        """
        Generate embedding for a single image.
        
        Args:
            image_path: Path to image file
            
        Returns:
            List of float values representing the embedding
        """
        try:
            image = self.load_image(image_path)
            image_tensor = self.preprocess(image).unsqueeze(0).to(self.device)
            
            with torch.no_grad():
                image_features = self.model.encode_image(image_tensor)
                # Normalize embeddings (L2 normalization)
                image_features = image_features / image_features.norm(dim=-1, keepdim=True)
                embedding = image_features.cpu().numpy()[0].tolist()
            
            return embedding
        except Exception as e:
            raise ValueError(f"Failed to generate embedding for {image_path}: {e}")
    
    def generate_embeddings_batch(self, image_paths: List[str]) -> Dict[str, List[float]]:
        """
        Generate embeddings for multiple images (batch processing).
        
        Args:
            image_paths: List of image file paths
            
        Returns:
            Dictionary mapping image paths to embeddings
        """
        results = {}
        errors = {}
        
        for image_path in image_paths:
            try:
                embedding = self.generate_embedding(image_path)
                results[image_path] = embedding
            except Exception as e:
                errors[image_path] = str(e)
        
        return {
            "embeddings": results,
            "errors": errors
        }


def main():
    """Command-line interface for CLIP service."""
    parser = argparse.ArgumentParser(description="CLIP Embedding Service")
    parser.add_argument(
        "--model",
        type=str,
        default="ViT-B/32",
        help="CLIP model name (default: ViT-B/32)"
    )
    parser.add_argument(
        "--device",
        type=str,
        choices=["cpu", "cuda"],
        help="Device to use (auto-detected if not specified)"
    )
    parser.add_argument(
        "--batch",
        action="store_true",
        help="Process multiple images (read paths from stdin, one per line)"
    )
    parser.add_argument(
        "image_paths",
        nargs="*",
        help="Image file paths to process"
    )
    
    args = parser.parse_args()
    
    # Initialize service
    service = CLIPEmbeddingService(model_name=args.model, device=args.device)
    
    if args.batch:
        # Read image paths from stdin
        image_paths = [line.strip() for line in sys.stdin if line.strip()]
        if not image_paths:
            print(json.dumps({"error": "No image paths provided"}, indent=2))
            sys.exit(1)
        
        results = service.generate_embeddings_batch(image_paths)
        print(json.dumps(results, indent=2))
    else:
        # Process single or multiple images from command line
        if not args.image_paths:
            print(json.dumps({"error": "No image paths provided"}, indent=2))
            sys.exit(1)
        
        if len(args.image_paths) == 1:
            # Single image
            try:
                embedding = service.generate_embedding(args.image_paths[0])
                result = {
                    "image_path": args.image_paths[0],
                    "embedding": embedding,
                    "embedding_size": len(embedding)
                }
                print(json.dumps(result, indent=2))
            except Exception as e:
                print(json.dumps({"error": str(e)}, indent=2))
                sys.exit(1)
        else:
            # Multiple images
            results = service.generate_embeddings_batch(args.image_paths)
            print(json.dumps(results, indent=2))


if __name__ == "__main__":
    main()

