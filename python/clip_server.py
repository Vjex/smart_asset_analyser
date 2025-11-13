#!/usr/bin/env python3
"""
CLIP HTTP Server for Flutter Asset Analyser

Optional HTTP server for faster batch processing.
Run with: python clip_server.py --port 8000
"""

import argparse
import json
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse, parse_qs
from pathlib import Path
from clip_service import CLIPEmbeddingService
import sys


class CLIPRequestHandler(BaseHTTPRequestHandler):
    """HTTP request handler for CLIP embedding service."""
    
    def __init__(self, *args, service=None, **kwargs):
        self.service = service
        super().__init__(*args, **kwargs)
    
    def do_GET(self):
        """Handle GET requests (health check)."""
        if self.path == "/health":
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(json.dumps({"status": "ok", "model": self.service.model_name}).encode())
        else:
            self.send_response(404)
            self.end_headers()
    
    def do_POST(self):
        """Handle POST requests (embedding generation)."""
        if self.path == "/embedding":
            content_length = int(self.headers["Content-Length"])
            post_data = self.rfile.read(content_length)
            
            try:
                data = json.loads(post_data.decode("utf-8"))
                image_path = data.get("image_path")
                
                if not image_path:
                    self.send_error(400, "Missing image_path")
                    return
                
                embedding = self.service.generate_embedding(image_path)
                
                response = {
                    "image_path": image_path,
                    "embedding": embedding,
                    "embedding_size": len(embedding)
                }
                
                self.send_response(200)
                self.send_header("Content-Type", "application/json")
                self.end_headers()
                self.wfile.write(json.dumps(response).encode())
                
            except Exception as e:
                self.send_response(500)
                self.send_header("Content-Type", "application/json")
                self.end_headers()
                self.wfile.write(json.dumps({"error": str(e)}).encode())
        
        elif self.path == "/embeddings":
            # Batch processing
            content_length = int(self.headers["Content-Length"])
            post_data = self.rfile.read(content_length)
            
            try:
                data = json.loads(post_data.decode("utf-8"))
                image_paths = data.get("image_paths", [])
                
                if not image_paths:
                    self.send_error(400, "Missing image_paths")
                    return
                
                results = self.service.generate_embeddings_batch(image_paths)
                
                self.send_response(200)
                self.send_header("Content-Type", "application/json")
                self.end_headers()
                self.wfile.write(json.dumps(results).encode())
                
            except Exception as e:
                self.send_response(500)
                self.send_header("Content-Type", "application/json")
                self.end_headers()
                self.wfile.write(json.dumps({"error": str(e)}).encode())
        else:
            self.send_response(404)
            self.end_headers()
    
    def log_message(self, format, *args):
        """Suppress default logging."""
        pass


def create_handler(service):
    """Create request handler with service."""
    def handler(*args, **kwargs):
        return CLIPRequestHandler(*args, service=service, **kwargs)
    return handler


def main():
    """Start HTTP server."""
    parser = argparse.ArgumentParser(description="CLIP HTTP Server")
    parser.add_argument(
        "--port",
        type=int,
        default=8000,
        help="Server port (default: 8000)"
    )
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
    
    args = parser.parse_args()
    
    print(f"Initializing CLIP service...", file=sys.stderr)
    service = CLIPEmbeddingService(model_name=args.model, device=args.device)
    
    handler = create_handler(service)
    server = HTTPServer(("localhost", args.port), handler)
    
    print(f"CLIP HTTP Server running on http://localhost:{args.port}", file=sys.stderr)
    print(f"Endpoints:", file=sys.stderr)
    print(f"  GET  /health - Health check", file=sys.stderr)
    print(f"  POST /embedding - Single image embedding", file=sys.stderr)
    print(f"  POST /embeddings - Batch embeddings", file=sys.stderr)
    
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nShutting down server...", file=sys.stderr)
        server.shutdown()


if __name__ == "__main__":
    main()

