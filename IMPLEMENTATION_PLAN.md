# Flutter Asset Analyser - Detailed Implementation Plan

## Project Overview

Create a Dart CLI package that detects visually identical/similar assets in Flutter projects using **Deep Visual Embeddings**. The package will generate an interactive HTML report with filtering capabilities.

## Command Structure

```bash
dart analyse assets [options]
```

**Note**: Since this is a Dart package (not Flutter), the command will be:
```bash
dart run analyser:analyse assets [options]
```

Or we can create a simpler entry point:
```bash
dart run bin/analyser.dart analyse assets [options]
```

## Core Requirements

1. ✅ CLI command: `dart analyse assets`
2. ✅ HTML report with similar assets
3. ✅ Filter by similarity percentage (0-100%)
4. ✅ Filter by asset type (Images, SVGs, Lottie/JSON)
5. ✅ Compare similarity for all asset types
6. ✅ Deep Visual Embeddings for accuracy

## Architecture Design

### Package Structure
```
analyser/
├── pubspec.yaml
├── README.md
├── requirements.txt               # Python dependencies
├── python/
│   ├── clip_service.py           # CLIP embedding service
│   ├── clip_server.py            # HTTP server (optional)
│   └── setup.py                  # Python package setup
├── bin/
│   └── analyser.dart              # CLI entry point
├── lib/
│   ├── analyser.dart              # Main export
│   └── src/
│       ├── cli/
│       │   └── command_handler.dart    # CLI command parsing
│       ├── discovery/
│       │   └── asset_discovery.dart    # Find assets in project
│       ├── embeddings/
│       │   ├── embedding_service.dart  # Deep visual embeddings
│       │   ├── python_bridge.dart      # Python CLIP bridge
│       │   └── fallback_embedder.dart  # Perceptual hash fallback
│       ├── processors/
│       │   ├── base_processor.dart     # Base interface
│       │   ├── image_processor.dart     # PNG, JPG, WebP
│       │   ├── svg_processor.dart      # SVG rasterization
│       │   └── lottie_processor.dart   # Lottie JSON processing
│       ├── similarity/
│       │   └── similarity_calculator.dart  # Cosine similarity
│       ├── models/
│       │   ├── asset_info.dart          # Asset metadata model
│       │   └── similarity_group.dart    # Group of similar assets
│       └── report/
│           └── html_generator.dart      # HTML report generation
└── test/
```

## Deep Visual Embeddings Strategy

### Primary Approach: CLIP Python Bridge ✅

**Why CLIP?**
- Best accuracy for visual similarity detection
- Pre-trained on large diverse dataset
- Excellent for semantic similarity (not just pixel-level)

**Implementation: Python Bridge (Selected)**

**Architecture:**
```
Dart CLI → Python Service (subprocess/HTTP) → CLIP Model → Embeddings → Dart
```

**Python Service:**
- Uses `transformers` library with CLIP model (Hugging Face)
- Or uses `clip-by-openai` package
- Exposes API endpoint or command-line interface
- Processes images and returns embeddings as JSON

**Communication Methods:**

1. **Subprocess (Recommended)**
   - Dart spawns Python process
   - Pass image paths via stdin or command args
   - Receive embeddings via stdout (JSON)
   - Pros: Simple, no network overhead
   - Cons: Process startup overhead

2. **HTTP Server (Alternative)**
   - Python runs as local HTTP server
   - Dart sends POST requests with image paths
   - Returns embeddings in JSON response
   - Pros: Faster for multiple images, persistent model
   - Cons: More complex setup

**Python Dependencies:**
```python
torch>=2.0.0
transformers>=4.30.0
pillow>=10.0.0
numpy>=1.24.0
clip-by-openai  # Alternative: open_clip
```

**Fallback: Perceptual Hash**
- If Python/CLIP unavailable, use perceptual hash
- Fast approximate matching
- Less accurate but works offline

### Embedding Generation Pipeline

1. **Preprocessing**:
   - Resize image to 224x224 (CLIP input size)
   - Normalize pixel values to [0, 1]
   - Convert to RGB format

2. **Model Inference**:
   - Load CLIP vision encoder
   - Generate 512-dimensional embedding vector
   - Normalize embedding (L2 normalization)

3. **Storage**:
   - Cache embeddings to avoid recomputation
   - Store in memory during analysis

## Asset Processing Details

### 1. Images (PNG, JPG, WebP)

**Processing Steps:**
```dart
1. Load image file using `package:image`
2. Convert to RGB format
3. Resize to 224x224 (maintaining aspect ratio with padding)
4. Normalize pixel values
5. Generate embedding via CLIP
6. Store embedding + metadata
```

**Supported formats:**
- PNG (with/without transparency)
- JPEG/JPG
- WebP

### 2. SVGs

**Processing Steps:**
```dart
1. Parse SVG XML using `package:xml`
2. Rasterize SVG to image:
   - Option A: Use `flutter_svg` package (if available)
   - Option B: Use `dart:ui` Picture class
   - Option C: Use external tool (ImageMagick, rsvg-convert)
3. Convert rasterized image to standard format
4. Generate embedding
5. Store for comparison
```

**Challenges:**
- SVG can have different sizes
- Need consistent rasterization size
- Handle viewBox and scaling

**Solution:**
- Rasterize at fixed size (e.g., 512x512)
- Use white background for transparent SVGs
- Normalize viewBox before rendering

### 3. Lottie JSONs

**Processing Steps:**
```dart
1. Parse Lottie JSON file
2. Extract key frames:
   - First frame (t=0)
   - Middle frame (t=duration/2)
   - Last frame (t=duration)
3. Render each frame to image:
   - Use `lottie` package or custom renderer
   - Or use external tool (lottie-web, etc.)
4. Generate embeddings for each frame
5. Compare using:
   - Average of frame embeddings
   - Best match (highest similarity)
   - Or compare all frames individually
```

**Lottie Structure:**
```json
{
  "v": "5.5.7",
  "fr": 60,
  "ip": 0,
  "op": 120,
  "w": 100,
  "h": 100,
  "assets": [...],
  "layers": [...]
}
```

**Frame Extraction:**
- Calculate frame number: `frame = (time * fps).floor()`
- Render frame at specific time
- Convert to image format

## Similarity Calculation

### Cosine Similarity

```dart
double cosineSimilarity(List<double> embedding1, List<double> embedding2) {
  double dotProduct = 0.0;
  double norm1 = 0.0;
  double norm2 = 0.0;
  
  for (int i = 0; i < embedding1.length; i++) {
    dotProduct += embedding1[i] * embedding2[i];
    norm1 += embedding1[i] * embedding1[i];
    norm2 += embedding2[i] * embedding2[i];
  }
  
  return dotProduct / (sqrt(norm1) * sqrt(norm2));
}
```

### Similarity Thresholds

- **0.95-1.0**: Visually identical (exact duplicates)
- **0.85-0.95**: Very similar (minor differences)
- **0.70-0.85**: Similar (same content, different style/size)
- **<0.70**: Different

### Grouping Algorithm

```dart
1. Generate embeddings for all assets
2. Compare all pairs (O(n²) comparisons)
3. For each pair with similarity >= threshold:
   - Add to similarity groups
4. Merge groups that share common assets
5. Sort groups by average similarity
```

## HTML Report Features

### Interactive Filters

1. **Similarity Percentage Slider**
   - Range: 0-100%
   - Real-time filtering
   - Show only groups above threshold

2. **Asset Type Filter**
   - Checkboxes: Images, SVGs, Lottie
   - Multi-select enabled
   - Filter groups by asset types

3. **Search by Filename**
   - Text input
   - Real-time search
   - Highlight matches

### Visual Comparison

- **Side-by-side layout**:
  - Show 2-4 similar assets per row
  - Thumbnail previews (click to enlarge)
  - Similarity percentage badge
  - File path and size info

- **Group View**:
  - Each group shows all similar assets
  - Average similarity score
  - Group size indicator

### Statistics Dashboard

- Total assets scanned
- Number of similarity groups found
- Average similarity per group
- Potential space savings (if duplicates found)
- Processing time

### Export Options

- Download report as JSON
- Export filtered results
- Copy asset paths to clipboard

## CLI Options

```bash
dart analyse assets [options]

Options:
  --threshold <0.0-1.0>      Similarity threshold (default: 0.85)
  --min-similarity <0-100>    Minimum similarity percentage (default: 85)
  --output <path>             Output HTML file path (default: asset_report.html)
  --types <types>              Asset types: images,svgs,lottie (default: all)
  --exclude <pattern>          Exclude files matching pattern (glob)
  --project-path <path>        Flutter project path (default: current directory)
  --model <path>               Path to CLIP model file (optional)
  --use-api                    Use HTTP API instead of local model
  --parallel <count>           Number of parallel workers (default: 4)
  --cache-embeddings           Cache embeddings to disk
```

## Implementation Phases

### Phase 1: Foundation (Week 1)
- [x] Project structure setup
- [ ] CLI command handler
- [ ] Asset discovery (pubspec.yaml + folder scanning)
- [ ] Basic models (AssetInfo, SimilarityGroup)
- [ ] Image processor (basic)
- [ ] Perceptual hash fallback

### Phase 2: Deep Embeddings (Week 2)
- [ ] Python CLIP service (clip_service.py)
- [ ] Python requirements and setup
- [ ] Dart-Python bridge (subprocess communication)
- [ ] Embedding service integration
- [ ] Image preprocessing pipeline
- [ ] Cosine similarity calculator
- [ ] Similarity grouping algorithm

### Phase 3: Asset Type Support (Week 3)
- [ ] SVG processor (rasterization)
- [ ] Lottie processor (frame extraction)
- [ ] Unified processing interface
- [ ] Type-specific optimizations

### Phase 4: HTML Report (Week 4)
- [ ] HTML template with filters
- [ ] JavaScript for interactivity
- [ ] Visual comparison layout
- [ ] Statistics dashboard
- [ ] Export functionality

### Phase 5: Polish & Testing (Week 5)
- [ ] Error handling
- [ ] Performance optimization
- [ ] Caching system
- [ ] Unit tests
- [ ] Documentation

## Technical Decisions

### 1. Model Choice: CLIP ViT-B/32 (via Python)
- **Library**: `transformers` (Hugging Face) or `clip-by-openai`
- **Model**: `openai/clip-vit-base-patch32`
- **Size**: ~150MB (downloaded automatically)
- **Accuracy**: Excellent for visual similarity
- **Speed**: ~50-100ms per image on CPU
- **Format**: PyTorch (handled by Python)

### 2. SVG Rasterization: dart:ui Picture
- Use Flutter's built-in SVG rendering
- Convert Picture to image bytes
- Consistent 512x512 output size

### 3. Lottie Rendering: External Tool
- Use `lottie-web` via Node.js (if available)
- Or parse JSON and render manually
- Extract 3 key frames for comparison

### 4. Caching Strategy
- Cache embeddings in `.analyser_cache/` folder
- Use file hash as cache key
- Invalidate on file modification

### 5. Performance Optimization
- Parallel processing (Isolate.spawn)
- Batch embedding generation
- Lazy loading in HTML report
- Progress indicators

## Dependencies

```yaml
dependencies:
  path: ^1.9.0
  yaml: ^3.1.2
  image: ^4.1.7
  xml: ^6.5.0
  args: ^2.4.2
  collection: ^1.18.0
  http: ^1.2.0  # For optional HTTP bridge
  
dev_dependencies:
  test: ^1.24.0
```

**Python Dependencies (requirements.txt):**
```txt
torch>=2.0.0
transformers>=4.30.0
pillow>=10.0.0
numpy>=1.24.0
# Alternative: clip-by-openai
```

## Testing Strategy

1. **Unit Tests**:
   - Similarity calculation
   - Asset discovery
   - Embedding generation
   - HTML generation

2. **Integration Tests**:
   - End-to-end CLI workflow
   - Different asset types
   - Edge cases (empty projects, no assets)

3. **Sample Data**:
   - Create test Flutter project with known duplicates
   - Various asset types
   - Different similarity levels

## Future Enhancements

1. **Advanced Features**:
   - Batch deletion of duplicates
   - Automatic asset optimization
   - Integration with CI/CD
   - VS Code extension

2. **Model Improvements**:
   - Support for multiple models
   - Custom model training
   - Model versioning

3. **Performance**:
   - GPU acceleration
   - Distributed processing
   - Incremental analysis

## Success Metrics

- ✅ Detects visually identical assets with >95% accuracy
- ✅ Processes 100 assets in <30 seconds
- ✅ HTML report loads in <2 seconds
- ✅ Supports all required asset types
- ✅ Works offline (with local model)

