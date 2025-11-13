# Flutter Asset Analyser - Deep Visual Embeddings Plan

## Overview
A Flutter package that detects visually identical/similar assets using Deep Visual Embeddings. Supports images (PNG, JPG, WebP), SVGs, and Lottie JSON animations.

## Architecture

### 1. Package Structure
```
analyser/
├── pubspec.yaml
├── README.md
├── bin/
│   └── analyser.dart (CLI entry point)
├── lib/
│   ├── analyser.dart (main export)
│   ├── src/
│   │   ├── asset_discovery.dart (find assets in project)
│   │   ├── embeddings/
│   │   │   ├── embedding_service.dart (deep visual embeddings)
│   │   │   └── models/ (pre-trained model integration)
│   │   ├── processors/
│   │   │   ├── image_processor.dart (PNG, JPG, WebP)
│   │   │   ├── svg_processor.dart (SVG to image conversion)
│   │   │   └── lottie_processor.dart (Lottie frame extraction)
│   │   ├── similarity/
│   │   │   └── similarity_calculator.dart (cosine similarity)
│   │   └── report/
│   │       └── html_generator.dart (HTML report with filtering)
└── test/
```

### 2. Deep Visual Embeddings Strategy

**Option A: CLIP (Recommended)**
- Use CLIP (Contrastive Language-Image Pre-training) model
- Pre-trained on large dataset, excellent for visual similarity
- Can use `tflite_flutter` or `image` package with ONNX runtime
- Or use HTTP API to Hugging Face Inference API

**Option B: ResNet/ImageNet Pre-trained**
- Use pre-trained ResNet50/ResNet101
- Extract features from penultimate layer
- Good for general image similarity

**Option C: MobileNet (Lightweight)**
- Lighter model, faster processing
- Good for mobile/CLI tools
- Trade-off: slightly less accurate

**Recommended: CLIP via ONNX Runtime or TensorFlow Lite**
- Best accuracy for visual similarity
- Can run locally without internet
- Good balance of speed and accuracy

### 3. Asset Processing Pipeline

#### Images (PNG, JPG, WebP)
1. Load image file
2. Resize to standard size (e.g., 224x224 for CLIP)
3. Normalize pixel values
4. Generate embedding via model
5. Store embedding for comparison

#### SVGs
1. Parse SVG file
2. Rasterize to image (use `flutter_svg` or `dart:ui` with Picture)
3. Convert to standard size
4. Generate embedding
5. Store for comparison

#### Lottie JSONs
1. Parse Lottie JSON
2. Extract key frames (first frame, middle frame, last frame)
3. Render each frame to image
4. Generate embeddings for each frame
5. Use average or best match for comparison
6. Store for comparison

### 4. Similarity Calculation

- Use **Cosine Similarity** between embeddings
- Range: 0.0 (completely different) to 1.0 (identical)
- Threshold: Default 0.95 for "identical", 0.85 for "very similar"
- Group similar assets by similarity percentage

### 5. HTML Report Features

- **Interactive filtering**:
  - Similarity percentage slider (0-100%)
  - Asset type filter (Images, SVGs, Lottie)
  - Search by filename
  
- **Visual comparison**:
  - Side-by-side comparison of similar assets
  - Show similarity percentage
  - Show file paths and sizes
  - Click to view full-size images
  
- **Statistics**:
  - Total assets scanned
  - Duplicate groups found
  - Potential space savings

### 6. CLI Command

```bash
dart run analyser:analyse assets [options]

Options:
  --threshold <0.0-1.0>    Similarity threshold (default: 0.85)
  --output <path>          Output HTML file path (default: asset_report.html)
  --types <types>           Asset types to scan (images,svgs,lottie) (default: all)
  --exclude <pattern>       Exclude files matching pattern
```

### 7. Dependencies Needed

```yaml
dependencies:
  path: ^1.8.0
  yaml: ^3.1.0
  image: ^4.0.0
  xml: ^6.0.0
  http: ^1.0.0
  
dev_dependencies:
  test: ^1.21.0
```

For Deep Learning:
- Option 1: `tflite_flutter` + pre-trained model file
- Option 2: `onnxruntime` (if available for Dart)
- Option 3: HTTP API to ML service (Hugging Face, etc.)
- Option 4: Use `package:image` with custom feature extraction

**Recommended Approach**: Start with a simpler feature extraction (histogram + perceptual hash) for MVP, then add deep embeddings as enhancement.

### 8. Implementation Phases

**Phase 1: MVP (Basic Similarity)**
- Asset discovery
- Basic image comparison (perceptual hash + histogram)
- HTML report generation
- CLI command

**Phase 2: Deep Embeddings**
- Integrate CLIP or ResNet model
- Generate embeddings for all assets
- Cosine similarity calculation

**Phase 3: Advanced Features**
- SVG support
- Lottie support
- Advanced filtering
- Batch operations

## Technical Challenges

1. **Model Integration**: Dart doesn't have native ML frameworks like Python
   - Solution: Use TensorFlow Lite or ONNX Runtime bindings
   - Or: Pre-process in Dart, send to external service
   - Or: Use simpler algorithms first (perceptual hash)

2. **SVG Rasterization**: Need to convert SVG to image
   - Solution: Use `flutter_svg` or `dart:ui` Picture class

3. **Lottie Frame Extraction**: Need to render Lottie frames
   - Solution: Use `lottie` package or parse JSON manually

4. **Performance**: Processing many assets can be slow
   - Solution: Parallel processing, caching embeddings

## Alternative: Hybrid Approach

Start with **Perceptual Hash (pHash)** + **Histogram Comparison**:
- Fast and works well for exact/very similar images
- No ML model needed
- Can add deep embeddings later for better accuracy

Then enhance with **Deep Visual Embeddings**:
- Better for semantically similar images
- More accurate similarity scores
- Requires model integration

