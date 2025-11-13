# Flutter Asset Analyser - Setup Guide

## Overview

This package detects visually identical/similar assets in Flutter projects using **CLIP (Deep Visual Embeddings)** via a Python bridge.

## Prerequisites

1. **Dart SDK** (3.0.0 or higher)
2. **Python 3.8+** with pip
3. **Flutter project** to analyze

## Installation

### 1. Install Python Dependencies

```bash
pip install -r requirements.txt
```

Or install manually:
```bash
pip install torch transformers pillow numpy clip-by-openai
```

**Note**: The first time you run the analyser, CLIP will download the model (~150MB). This happens automatically.

### 2. Install Dart Dependencies

```bash
dart pub get
```

## Usage

### Basic Usage

From your Flutter project root:

```bash
dart run analyser:analyse assets
```

Or if you're in the analyser package directory:

```bash
dart run bin/analyser.dart analyse assets --project-path /path/to/flutter/project
```

### Command Options

```bash
dart run analyser:analyse assets [options]

Options:
  --threshold <0.0-1.0>      Similarity threshold (default: 0.85)
  --min-similarity <0-100>   Minimum similarity percentage (default: 85)
  --output <path>            Output HTML file path (default: asset_report.html)
  --types <types>            Asset types: images,svgs,lottie (comma-separated, default: all)
  --exclude <pattern>         Exclude files matching pattern (glob)
  --project-path <path>       Flutter project path (default: current directory)
  --python-path <path>        Path to Python executable (default: python3)
  --use-server               Use HTTP server mode for Python bridge
  --server-port <port>        HTTP server port (default: 8000)
  --parallel <count>          Number of parallel workers (default: 4)
  --cache-embeddings          Cache embeddings to disk (default: true)
```

### Examples

```bash
# Analyze all assets with default settings
dart run analyser:analyse assets

# Only analyze images with 90% similarity threshold
dart run analyser:analyse assets --types images --threshold 0.90 --min-similarity 90

# Custom output location
dart run analyser:analyse assets --output reports/my_analysis.html

# Exclude test assets
dart run analyser:analyse assets --exclude "**/test/**"

# Use HTTP server mode (faster for large projects)
dart run analyser:analyse assets --use-server --server-port 8000
```

## How It Works

1. **Asset Discovery**: Scans `pubspec.yaml` and `assets/` folder for images, SVGs, and Lottie files
2. **Embedding Generation**: Uses CLIP model (via Python) to generate visual embeddings
3. **Similarity Calculation**: Compares embeddings using cosine similarity
4. **Grouping**: Groups similar assets together
5. **Report Generation**: Creates interactive HTML report with filtering

## Python CLIP Service

The package uses a Python service (`python/clip_service.py`) that:

- Loads the CLIP model (ViT-B/32 by default)
- Processes images and generates embeddings
- Returns embeddings as JSON

### Running Python Service Manually

For debugging or testing:

```bash
# Single image
python python/clip_service.py path/to/image.png

# Batch processing
echo -e "image1.png\nimage2.png" | python python/clip_service.py --batch

# HTTP server mode
python python/clip_server.py --port 8000
```

## HTML Report Features

The generated HTML report includes:

- **Statistics Dashboard**: Total assets, groups, pairs, etc.
- **Interactive Filters**:
  - Similarity percentage slider (0-100%)
  - Asset type filter (Images, SVGs, Lottie)
  - Search by filename
- **Visual Comparison**: Side-by-side comparison of similar assets
- **Group View**: All similar assets grouped together

## Troubleshooting

### Python Not Found

If you get "Python not found" error:

```bash
# Specify Python path explicitly
dart run analyser:analyse assets --python-path /usr/bin/python3
```

### CLIP Model Download Issues

The first run will download the CLIP model (~150MB). If it fails:

1. Check internet connection
2. Ensure sufficient disk space
3. Try running Python service manually to see detailed errors

### Missing Dependencies

If Python dependencies are missing:

```bash
pip install -r requirements.txt
```

### Permission Errors

If you get permission errors when writing cache:

- The cache is stored in `.analyser_cache/` directory
- Ensure you have write permissions in the project directory

## Performance Tips

1. **Use HTTP Server Mode**: For large projects, use `--use-server` flag for faster processing
2. **Enable Caching**: Embeddings are cached by default (use `--cache-embeddings`)
3. **Filter Asset Types**: Use `--types` to only analyze specific types
4. **Exclude Patterns**: Use `--exclude` to skip unnecessary files

## Current Limitations

- **SVG Support**: Currently, SVGs need to be rasterized first (coming soon)
- **Lottie Support**: Lottie frame extraction not yet implemented (coming soon)
- **Image Formats**: Currently supports PNG, JPG, JPEG, WebP

## Next Steps

The package is ready for basic image analysis. SVG and Lottie support will be added in future updates.

## Support

For issues or questions, please check the main README.md or create an issue on GitHub.

