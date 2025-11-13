# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.6] - 2025-01-27

### Fixed
- Fixed dependency detection to check for `transformers` instead of `clip-by-openai`
- Updated `checkDependencies()` to correctly detect installed Python packages
- Added fallback check for backwards compatibility

## [0.1.5] - 2025-01-27

### Fixed
- **CRITICAL**: Removed `clip-by-openai` dependency which had conflicts with PyTorch 2.0+
- Switched to `transformers` library (Hugging Face) for CLIP implementation
- Updated all Python code to use `transformers.CLIPModel` instead of `clip-by-openai`
- Fixed dependency resolution errors when installing from pub.dev

### Changed
- Updated `requirements.txt` to remove `clip-by-openai`
- Updated all documentation to reflect new dependency requirements
- Python code now uses Hugging Face transformers for better compatibility

## [0.1.4] - 2025-01-27

### Added
- Requirements helper with automatic `requirements.txt` detection
- `--show-requirements` flag to display installation instructions
- Automatic `pip` vs `pip3` detection

## [0.1.3] - 2025-01-27

### Fixed
- Fixed Python script location when installed from pub.dev
- Updated package name references

## [0.1.2] - 2025-01-27

### Fixed
- Fixed executable name in pubspec.yaml
- Renamed binary file to match executable name

## [0.1.1] - 2025-01-27

### Changed
- Package name updated to `smart_asset_analyser`
- Updated all documentation to use version dependencies (`^0.1.0`) instead of path dependencies
- Improved Python script location resolution using `package_config` for pub.dev compatibility
- Updated CLI command to `dart run smart_asset_analyser:analyse assets`

### Added
- Example Flutter project in `example/` folder
- Comprehensive example project documentation
- Better error messages for Python script location

### Fixed
- Python scripts now work correctly when package is installed from pub.dev
- All package references updated to `smart_asset_analyser`
- CLI argument parser fixed

## [0.1.0] - 2025-01-27

### Added
- Initial release of Smart Asset Analyser
- Deep Visual Embeddings using CLIP model via Python bridge
- Support for multiple asset types:
  - Images (PNG, JPG, JPEG, WebP, GIF, BMP)
  - SVGs (rasterized for comparison)
  - Lottie animations (key frames extracted)
- Interactive HTML report with filtering:
  - Similarity percentage slider (0-100%)
  - Asset type filter (Images, SVGs, Lottie)
  - Search by filename
- CLI command: `dart run smart_asset_analyser:analyse assets`
- Configurable similarity thresholds
- Embedding caching for faster subsequent runs
- Batch processing support
- HTTP server mode for faster processing
- Comprehensive documentation

### Technical Details
- Uses CLIP ViT-B/32 model for visual embeddings
- Cosine similarity calculation for comparison
- Union-find algorithm for grouping similar assets
- Python bridge for CLIP model integration
- SVG rasterization using cairosvg
- Lottie frame extraction using lottie

