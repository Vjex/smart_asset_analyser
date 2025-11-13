# Smart Asset Analyser

A powerful Flutter package that detects visually identical and similar assets in your Flutter project using **Deep Visual Embeddings (CLIP)**.

## Features

- 🔍 **Deep Visual Embeddings**: Uses CLIP model for accurate visual similarity detection
- 🖼️ **Multiple Asset Types**: Supports images (PNG, JPG, WebP), SVGs, and Lottie JSON animations
- 📊 **Interactive HTML Report**: Beautiful, filterable HTML report with similarity percentages
- ⚡ **Fast Processing**: Efficient batch processing with caching
- 🎯 **Configurable**: Customizable similarity thresholds and filters

## Quick Start

### 1. Install Python Dependencies (One-time)

**🎯 Easy Way - Automatic Detection:**

The package automatically finds `requirements.txt` for you! Just run:

```bash
# In your Flutter project, run:
dart run smart_asset_analyser analyse assets --show-requirements
```

This will display:
- ✅ Exact path to `requirements.txt`
- ✅ Ready-to-use installation command

Then simply copy and run the shown command:
```bash
pip install -r "<path-shown>"
```

**💡 Pro Tip:** If you try to run the analyser without Python dependencies, it will automatically show you where `requirements.txt` is located and provide the exact installation command!

**Alternative - Manual Installation:**
```bash
pip install torch transformers pillow numpy cairosvg lottie
```

**Note**: 
- The first run will automatically download the CLIP model (~150MB).
- If you see a pip version warning, you can upgrade pip with: `python3 -m pip install --upgrade pip` (optional, not required).

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
dart run smart_asset_analyser analyse assets
```

**Note**: The correct command is `dart run smart_asset_analyser analyse assets` (space, not colon).

### 4. View Results

Open `asset_report.html` in your browser!

## Usage Examples

```bash
# Basic analysis
dart run smart_asset_analyser analyse assets

# Find requirements.txt location
dart run smart_asset_analyser analyse assets --show-requirements

# Only images
dart run smart_asset_analyser analyse assets --types images

# Higher similarity threshold
dart run smart_asset_analyser analyse assets --threshold 0.95 --min-similarity 95

# Custom output location
dart run smart_asset_analyser analyse assets --output reports/duplicates.html

# Exclude test assets
dart run smart_asset_analyser analyse assets --exclude "**/test/**"
```

## Command Options

```bash
dart run smart_asset_analyser analyse assets [options]

Options:
  --show-requirements          Show location of requirements.txt file
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

### Finding requirements.txt

**Easy Discovery:**
```bash
dart run smart_asset_analyser analyse assets --show-requirements
```

**What you'll see:**
```
🔍 Finding requirements.txt...

✅ Found requirements.txt at:
   /path/to/smart_asset_analyser-0.1.1/requirements.txt

📦 Install Python dependencies with:
   pip install -r "/path/to/smart_asset_analyser-0.1.1/requirements.txt"
```

**Automatic Detection:**
The tool automatically finds `requirements.txt` when dependencies are missing, so you don't need to search for it manually!

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
- `transformers` - CLIP implementation (Hugging Face)
- `pillow` - Image processing
- `cairosvg` - SVG rasterization
- `lottie` - Lottie frame extraction

**Easy Installation (Recommended):**

The package automatically detects `requirements.txt` location. Just run:

```bash
dart run smart_asset_analyser analyse assets --show-requirements
```

This will show you:
- 📄 Exact path to `requirements.txt`
- 📦 Ready-to-use `pip install` command

Simply copy and run the command shown in the output!

**What happens automatically:**
- When dependencies are missing, the tool shows the path automatically
- No need to manually search for the file
- Works whether installed from pub.dev or used locally

**Manual Installation:**
```bash
pip install torch transformers pillow numpy cairosvg lottie
```

## Example Project

An example Flutter project is included in the `example/` folder. To try it:

```bash
cd example
flutter pub get
dart run smart_asset_analyser analyse assets
```

This demonstrates how to use the package in a real Flutter project.

## Troubleshooting

### Python Not Found
```bash
dart run smart_asset_analyser analyse assets --python-path /usr/local/bin/python3
```

### Missing Dependencies

**Automatic Help:**
When you run the analyser without Python dependencies, you'll see:

```
⚠️  Python dependencies not found!

📄 Found requirements.txt at:
   /path/to/smart_asset_analyser-0.1.1/requirements.txt

✅ Install Python dependencies with:
   pip install -r "/path/to/smart_asset_analyser-0.1.1/requirements.txt"
```

Simply copy and run the shown command!

**Manual Discovery:**
If you want to find `requirements.txt` before running:
```bash
dart run smart_asset_analyser analyse assets --show-requirements
```

This will show you the exact path and installation command.

### CLIP Model Download Issues
- Check internet connection
- Ensure sufficient disk space (~200MB)
- Try running Python service manually to see detailed errors

## Documentation

- **[QUICK_START.md](QUICK_START.md)** - Quick setup guide
- **[USAGE.md](USAGE.md)** - Detailed usage instructions
- **[INSTALLATION.md](INSTALLATION.md)** - Installation guide
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
