# How to Use Flutter Asset Analyser in Your Projects

## Quick Start

### 1. Install Python Dependencies

First, ensure you have Python 3.8+ installed, then install the required packages:

```bash
cd /path/to/analyser
pip install -r requirements.txt
```

Or install manually:
```bash
pip install torch transformers pillow numpy clip-by-openai cairosvg python-lottie
```

**Note**: The first run will download the CLIP model (~150MB), which happens automatically.

### 2. Using the Package

You have two options to use this package in other Flutter projects:

### Add to Your Flutter Project

1. **Add to your Flutter project's `pubspec.yaml` as a dev dependency**:

```yaml
dev_dependencies:
  smart_asset_analyser: ^0.1.1
```

**Why dev dependency?**
- It's a development tool for analyzing assets
- Not needed at runtime in your app
- Keeps production builds smaller

2. **Install dependencies**:

```bash
cd /path/to/your/flutter/project
flutter pub get
```

3. **Run from your Flutter project root**:

```bash
dart run smart_asset_analyser analyse assets
```

**Note**: Use a space between `smart_asset_analyser` and `analyse`, not a colon.

**Alternative: Local Path** (for development/testing):
```yaml
dev_dependencies:
  smart_asset_analyser:
    path: /absolute/path/to/smart_asset_analyser
```

## Usage Examples

### Basic Analysis

Analyze all assets in your Flutter project:

```bash
# From your Flutter project root
dart run analyser:analyse assets
```

This will:
- Discover all assets from `pubspec.yaml` and `assets/` folder
- Generate embeddings using CLIP
- Create `asset_report.html` with results

### Analyze Specific Asset Types

```bash
# Only images
dart run analyser:analyse assets --types images

# Only SVGs
dart run analyser:analyse assets --types svgs

# Only Lottie files
dart run analyser:analyse assets --types lottie

# Multiple types
dart run analyser:analyse assets --types images,svgs
```

### Custom Similarity Threshold

```bash
# Higher threshold (more strict, fewer matches)
dart run analyser:analyse assets --threshold 0.95 --min-similarity 95

# Lower threshold (more lenient, more matches)
dart run analyser:analyse assets --threshold 0.75 --min-similarity 75
```

### Custom Output Location

```bash
dart run analyser:analyse assets --output reports/duplicate_assets.html
```

### Exclude Certain Files

```bash
# Exclude test assets
dart run analyser:analyse assets --exclude "**/test/**"

# Exclude specific patterns
dart run analyser:analyse assets --exclude "**/*_test.*"
```

### Using HTTP Server Mode (Faster for Large Projects)

```bash
# Start server mode (keeps model loaded in memory)
dart run analyser:analyse assets --use-server --server-port 8000
```

### Specify Python Path

If Python is not in your PATH:

```bash
dart run analyser:analyse assets --python-path /usr/local/bin/python3
```

## Complete Command Reference

```bash
dart run analyser:analyse assets [options]

Options:
  --threshold <0.0-1.0>      Similarity threshold (default: 0.85)
  --min-similarity <0-100>    Minimum similarity percentage (default: 85)
  --output <path>             Output HTML file path (default: asset_report.html)
  --types <types>              Asset types: images,svgs,lottie (comma-separated, default: all)
  --exclude <pattern>          Exclude files matching pattern (glob)
  --project-path <path>        Flutter project path (default: current directory)
  --python-path <path>         Path to Python executable (default: python3)
  --use-server                 Use HTTP server mode for Python bridge
  --server-port <port>         HTTP server port (default: 8000)
  --parallel <count>           Number of parallel workers (default: 4)
  --cache-embeddings           Cache embeddings to disk (default: true)
```

## Step-by-Step Example

Let's say you have a Flutter project at `/Users/me/my_flutter_app`:

### Step 1: Navigate to Your Flutter Project

```bash
cd /Users/me/my_flutter_app
```

### Step 2: Add the Package (if using as dependency)

Edit `pubspec.yaml`:

```yaml
dev_dependencies:
  analyser:
    path: /path/to/analyser  # Update this path
```

Then run:
```bash
flutter pub get
```

### Step 3: Run the Analyser

```bash
dart run analyser:analyse assets
```

### Step 4: View Results

Open the generated `asset_report.html` in your browser:

```bash
open asset_report.html  # macOS
# or
xdg-open asset_report.html  # Linux
# or
start asset_report.html  # Windows
```

## Project Structure

The analyser will look for assets in:

1. **`pubspec.yaml`**: Assets listed in the `flutter.assets` section
2. **`assets/` folder**: All files in the assets directory (if it exists)

Example `pubspec.yaml`:
```yaml
flutter:
  assets:
    - assets/images/
    - assets/icons/logo.svg
    - assets/animations/loading.json
```

## Understanding the Report

The HTML report includes:

1. **Statistics Dashboard**:
   - Total assets scanned
   - Number of similarity groups found
   - Number of similar pairs
   - Minimum similarity threshold

2. **Interactive Filters**:
   - **Similarity Slider**: Adjust minimum similarity (0-100%)
   - **Type Filters**: Show/hide Images, SVGs, or Lottie files
   - **Search Box**: Search by filename

3. **Similarity Groups**:
   - Groups of visually similar assets
   - Side-by-side comparison
   - Similarity percentage for each pair
   - File paths and sizes

## Troubleshooting

### Python Not Found

```bash
# Check Python installation
python3 --version

# If not found, specify path explicitly
dart run analyser:analyse assets --python-path /usr/local/bin/python3
```

### Missing Python Dependencies

```bash
# Install dependencies
cd /path/to/analyser
pip install -r requirements.txt

# Verify installation
python3 -c "import torch, clip, cairosvg; print('OK')"
```

### CLIP Model Download Issues

The first run downloads the CLIP model. If it fails:
- Check internet connection
- Ensure sufficient disk space (~200MB)
- Try running Python service manually:
  ```bash
  python3 python/clip_service.py test_image.png
  ```

### SVG/Lottie Processing Fails

Ensure additional dependencies are installed:

```bash
pip install cairosvg python-lottie
```

### Permission Errors

If you get permission errors:
- Ensure write permissions in project directory
- Check cache directory (`.analyser_cache/`) permissions

## Performance Tips

1. **Use Caching**: Embeddings are cached by default. Subsequent runs are faster.

2. **HTTP Server Mode**: For large projects, use `--use-server` to keep the model loaded:
   ```bash
   dart run analyser:analyse assets --use-server
   ```

3. **Filter Asset Types**: Only analyze what you need:
   ```bash
   dart run analyser:analyse assets --types images
   ```

4. **Exclude Patterns**: Skip unnecessary files:
   ```bash
   dart run analyser:analyse assets --exclude "**/test/**"
   ```

## Integration with CI/CD

You can integrate this into your CI/CD pipeline:

```yaml
# Example GitHub Actions
- name: Analyze Assets
  run: |
    pip install -r analyser/requirements.txt
    dart run analyser:analyse assets --output reports/asset_analysis.html
```

## Next Steps

1. Run the analyser on your project
2. Review the HTML report
3. Identify duplicate/similar assets
4. Remove unnecessary duplicates to reduce app size
5. Re-run periodically to catch new duplicates

## Support

For issues or questions:
- Check the main `README.md`
- Review `SETUP.md` for detailed setup
- Check `IMPLEMENTATION_PLAN.md` for technical details

