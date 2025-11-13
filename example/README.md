# Example Flutter Project

This is an example Flutter project to demonstrate how to use `smart_asset_analyser` as a **dev dependency**.

## Setup

1. **Install Python Dependencies** (if not already installed):
   ```bash
   cd ..
   pip install -r requirements.txt
   ```

2. **Get Flutter Dependencies**:
   ```bash
   cd example
   flutter pub get
   ```

## How It's Configured

The `pubspec.yaml` shows how to add `smart_asset_analyser` as a dev dependency:

```yaml
dev_dependencies:
  smart_asset_analyser:
    path: ../  # Local path for development
  
  # When published, use version dependency:
  # smart_asset_analyser: ^0.1.1
```

**Why dev dependency?**
- It's a development tool, not needed at runtime
- Keeps it out of production builds
- Reduces final app size

## Usage

Run the asset analyser from the example project root:

```bash
dart run smart_asset_analyser:analyse assets
```

This will:
- Scan all assets in `assets/` folder
- Generate embeddings using CLIP
- Create `asset_report.html` with results

## Example Assets

The `assets/` folder contains sample assets for testing:
- `images/` - Sample images (PNG, JPG)
- `icons/` - SVG icons
- `animations/` - Lottie JSON files

## View Results

After running the analyser, open the generated report:

```bash
open asset_report.html  # macOS
# or
xdg-open asset_report.html  # Linux
# or
start asset_report.html  # Windows
```

## Custom Options

You can use various options:

```bash
# Only analyze images
dart run smart_asset_analyser:analyse assets --types images

# Higher similarity threshold
dart run smart_asset_analyser:analyse assets --threshold 0.95

# Custom output location
dart run smart_asset_analyser:analyse assets --output reports/analysis.html
```

