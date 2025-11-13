# Quick Start Guide

## 1. Setup (One-time)

```bash
# Navigate to smart_asset_analyser package
cd /path/to/smart_asset_analyser

# Install Python dependencies
pip install -r requirements.txt
```

## 2. Add to Your Flutter Project

In your Flutter project's `pubspec.yaml`:

```yaml
dev_dependencies:
  smart_asset_analyser: ^0.1.0
```

Then run:
```bash
cd /path/to/your/flutter/project
flutter pub get
dart run smart_asset_analyser:analyse assets
```

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
dart run smart_asset_analyser:analyse assets

# Only images
dart run smart_asset_analyser:analyse assets --types images

# Custom threshold
dart run smart_asset_analyser:analyse assets --threshold 0.90

# Custom output
dart run smart_asset_analyser:analyse assets --output my_report.html
```

## Example Project

Try the included example project:

```bash
cd example
flutter pub get
dart run smart_asset_analyser:analyse assets
```

That's it! 🎉
