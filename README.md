# Flutter Asset Analyser

A powerful Flutter package that detects visually identical and similar assets in your Flutter project using **Deep Visual Embeddings (CLIP)**.

## Features

- 🔍 **Deep Visual Embeddings**: Uses CLIP model for accurate visual similarity detection
- 🖼️ **Multiple Asset Types**: Supports images (PNG, JPG, WebP), SVGs, and Lottie JSON animations
- 📊 **Interactive HTML Report**: Beautiful, filterable HTML report with similarity percentages
- ⚡ **Fast Processing**: Efficient batch processing with caching
- 🎯 **Configurable**: Customizable similarity thresholds and filters

## Quick Start

### 1. Install Python Dependencies (One-time)

```bash
cd /path/to/analyser
pip install -r requirements.txt
```

### 2. Add to Your Flutter Project

Add to your Flutter project's `pubspec.yaml` as a **dev dependency**:

```yaml
dev_dependencies:
  smart_asset_analyser: ^0.1.1
```

Then:
```bash
cd /path/to/your/flutter/project
flutter pub get
```

**Note**: This is a dev dependency because it's a development tool for analyzing assets, not needed at runtime.

### 3. Run the Analyser

```bash
dart run smart_asset_analyser:analyse assets
```

### 4. View Results

Open `asset_report.html` in your browser!

## Usage Examples

```bash
# Basic analysis
dart run smart_asset_analyser:analyse assets

# Only images
dart run smart_asset_analyser:analyse assets --types images

# Higher similarity threshold
dart run smart_asset_analyser:analyse assets --threshold 0.95 --min-similarity 95

# Custom output location
dart run smart_asset_analyser:analyse assets --output reports/duplicates.html

# Exclude test assets
dart run smart_asset_analyser:analyse assets --exclude "**/test/**"
```

## Command Options

```bash
dart run smart_asset_analyser:analyse assets [options]

Options:
  --threshold <0.0-1.0>      Similarity threshold (default: 0.85)
  --min-similarity <0-100>    Minimum similarity percentage (default: 85)
  --output <path>             Output HTML file path (default: asset_report.html)
  --types <types>              Asset types: images,svgs,lottie (comma-separated, default: all)
  --exclude <pattern>          Exclude files matching pattern (glob)
  --project-path <path>        Flutter project path (default: current directory)
  --python-path <path>         Path to Python executable (default: python3)
  --use-server                 Use HTTP server mode for Python bridge (faster)
  --server-port <port>         HTTP server port (default: 8000)
  --cache-embeddings           Cache embeddings to disk (default: true)
```

## How It Works

1. **Asset Discovery**: Scans `pubspec.yaml` and `assets/` folders to find all assets
2. **Processing**: 
   - Images: Direct processing
   - SVGs: Rasterized to PNG images
   - Lottie: Key frames extracted and processed
3. **Embedding Generation**: Uses CLIP model (via Python) to generate visual embeddings
4. **Similarity Calculation**: Compares embeddings using cosine similarity
5. **Report Generation**: Creates an interactive HTML report with filtering options

## Report Features

The generated HTML report includes:

- **Statistics Dashboard**: Total assets, groups, pairs, potential savings
- **Interactive Filters**:
  - Similarity percentage slider (0-100%)
  - Asset type filter (Images, SVGs, Lottie)
  - Search by filename
- **Visual Comparison**: Side-by-side comparison with similarity percentage
- **Group View**: All similar assets grouped together

## Supported Asset Types

- **Images**: PNG, JPG, JPEG, WebP, GIF, BMP
- **SVGs**: Scalable Vector Graphics (rasterized for comparison)
- **Lottie**: JSON animation files (key frames extracted and averaged)

## Prerequisites

- **Python 3.8+** with pip
- **Dart SDK 3.0+**
- **Flutter project** with assets

## Installation Details

### Python Dependencies

The package requires:
- `torch` - PyTorch for CLIP model
- `transformers` or `clip-by-openai` - CLIP implementation
- `pillow` - Image processing
- `cairosvg` - SVG rasterization
- `python-lottie` - Lottie frame extraction

Install with:
```bash
pip install -r requirements.txt
```

**Note**: First run will download CLIP model (~150MB) automatically.

## Example Project

An example Flutter project is included in the `example/` folder. To try it:

```bash
cd example
flutter pub get
dart run smart_asset_analyser:analyse assets
```

This demonstrates how to use the package in a real Flutter project.

## Troubleshooting

### Python Not Found
```bash
dart run smart_asset_analyser:analyse assets --python-path /usr/local/bin/python3
```

### Missing Dependencies
```bash
pip install -r requirements.txt
```

### CLIP Model Download Issues
- Check internet connection
- Ensure sufficient disk space (~200MB)
- Try running Python service manually to see detailed errors

## Documentation

- **[QUICK_START.md](QUICK_START.md)** - Quick setup guide
- **[USAGE.md](USAGE.md)** - Detailed usage instructions
- **[EXAMPLE.md](EXAMPLE.md)** - Complete walkthrough example
- **[SETUP.md](SETUP.md)** - Detailed setup guide
- **[IMPLEMENTATION_PLAN.md](IMPLEMENTATION_PLAN.md)** - Technical details

## Performance Tips

1. **Use Caching**: Embeddings are cached by default for faster subsequent runs
2. **HTTP Server Mode**: Use `--use-server` for large projects (keeps model in memory)
3. **Filter Types**: Only analyze what you need with `--types`
4. **Exclude Patterns**: Skip unnecessary files with `--exclude`

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

MIT License
