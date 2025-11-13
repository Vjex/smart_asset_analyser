# Quick Start Guide

## 1. Setup (One-time)

**🎯 Easy Way - Automatic Detection:**

The package automatically finds `requirements.txt` for you! Just run:

```bash
# In your Flutter project, run:
dart run smart_asset_analyser analyse assets --show-requirements
```

This will show you the exact path and installation command. Simply copy and run it!

**💡 Pro Tip:** If you try to run the analyser without Python dependencies, it will automatically show you where `requirements.txt` is located!

**Alternative - Manual Installation:**
```bash
pip install torch transformers pillow numpy clip-by-openai cairosvg lottie
```

## 2. Add to Your Flutter Project

In your Flutter project's `pubspec.yaml`:

```yaml
dev_dependencies:
  smart_asset_analyser: ^0.1.1
```

Then run:
```bash
cd /path/to/your/flutter/project
flutter pub get
dart run smart_asset_analyser analyse assets
```

**Note**: Use a space between `smart_asset_analyser` and `analyse`, not a colon.

**Note**: For local development before publishing:
```yaml
dev_dependencies:
  smart_asset_analyser:
    path: /absolute/path/to/smart_asset_analyser
```

## 3. View Results

Open the generated `asset_report.html` in your browser!

## Common Commands

```bash
# Basic analysis
dart run smart_asset_analyser analyse assets

# Find requirements.txt
dart run smart_asset_analyser analyse assets --show-requirements

# Only images
dart run smart_asset_analyser analyse assets --types images

# Custom threshold
dart run smart_asset_analyser analyse assets --threshold 0.90

# Custom output
dart run smart_asset_analyser analyse assets --output my_report.html
```

## Example Project

Try the included example project:

```bash
cd example
flutter pub get
dart run smart_asset_analyser analyse assets
```

That's it! 🎉
