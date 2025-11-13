# Complete Example: Using Analyser in a Flutter Project

## Scenario

You have a Flutter project at `/Users/john/my_app` and want to find duplicate assets.

## Step 1: Setup Python Dependencies

```bash
# Navigate to analyser package
cd /Users/vishalverma/FlutterProjectNew/analyser

# Install Python dependencies (one-time setup)
pip install -r requirements.txt
```

Expected output:
```
Collecting torch...
Collecting transformers...
...
Successfully installed torch-2.0.0 transformers-4.30.0 ...
```

## Step 2: Add Package to Your Flutter Project

Edit `/Users/john/my_app/pubspec.yaml`:

```yaml
name: my_app
description: My Flutter app

dev_dependencies:
  analyser:
    path: /Users/vishalverma/FlutterProjectNew/analyser
  flutter_test:
    sdk: flutter
```

Then run:
```bash
cd /Users/john/my_app
flutter pub get
```

## Step 3: Run the Analyser

```bash
cd /Users/john/my_app
dart run analyser:analyse assets
```

Expected output:
```
🔍 Flutter Asset Analyser

Project: /Users/john/my_app
Threshold: 0.85 (85%)
Types: Images, SVGs, Lottie

Checking Python CLIP service...
✓ Python CLIP service ready

Discovering assets...
Found 45 assets

Processing assets (rasterizing SVG, extracting Lottie frames)...
  Rasterizing SVG: logo.svg
  Extracting Lottie frames: loading.json
Generating embeddings for 45 assets (48 images)...
Generated 45 embeddings

Calculating similarities...
Found 12 similar pairs

Grouping similar assets...
Found 5 similarity groups

Groups above 85% similarity: 5

Generating HTML report...
✓ Report generated: asset_report.html

Summary:
  Total assets: 45
  Similar pairs: 12
  Similarity groups: 5
  Potential space savings: 2.34 MB

Done! Open asset_report.html in your browser to view the report.
```

## Step 4: View the Report

```bash
open asset_report.html
```

The report will show:
- Statistics dashboard
- Interactive filters
- Groups of similar assets
- Visual comparisons

## Advanced Examples

### Example 1: Only Analyze Images

```bash
dart run analyser:analyse assets --types images
```

### Example 2: Higher Similarity Threshold

```bash
dart run analyser:analyse assets --threshold 0.95 --min-similarity 95
```

### Example 3: Custom Output Location

```bash
dart run analyser:analyse assets --output reports/duplicates.html
```

### Example 4: Exclude Test Assets

```bash
dart run analyser:analyse assets --exclude "**/test/**"
```

### Example 5: Use HTTP Server Mode (Faster)

```bash
dart run analyser:analyse assets --use-server
```

## Troubleshooting

### Issue: "Python not found"

**Solution**: Specify Python path explicitly:
```bash
dart run analyser:analyse assets --python-path /usr/local/bin/python3
```

### Issue: "Missing required package"

**Solution**: Install Python dependencies:
```bash
cd /Users/vishalverma/FlutterProjectNew/analyser
pip install -r requirements.txt
```

### Issue: "CLIP model download failed"

**Solution**: 
- Check internet connection
- Ensure sufficient disk space (~200MB)
- Try again (model download happens automatically)

## Project Structure

Your Flutter project should have assets in:

```
my_app/
├── pubspec.yaml
├── assets/
│   ├── images/
│   │   ├── icon1.png
│   │   └── icon2.png
│   ├── icons/
│   │   └── logo.svg
│   └── animations/
│       └── loading.json
```

The analyser will find assets from:
1. `pubspec.yaml` → `flutter.assets` section
2. `assets/` folder (if it exists)

## Next Steps

1. Review the HTML report
2. Identify duplicate/similar assets
3. Remove unnecessary duplicates
4. Re-run to verify cleanup
5. Add to CI/CD for continuous monitoring

