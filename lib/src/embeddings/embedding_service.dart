import 'dart:io';
import 'dart:convert';
import 'dart:math' as math;
import 'package:path/path.dart' as path;
import '../models/asset_info.dart';
import '../processors/svg_processor.dart';
import '../processors/lottie_processor.dart';
import 'python_bridge.dart';

/// Service for generating embeddings for assets
class EmbeddingService {
  final PythonBridge pythonBridge;
  final String cacheDir;
  final bool useCache;
  final String? pythonPath;
  final String projectRoot;
  final SvgProcessor? _svgProcessor;
  final LottieProcessor? _lottieProcessor;
  final List<String> _tempFiles = []; // Track temp files for cleanup

  EmbeddingService({
    required this.pythonBridge,
    String? cacheDir,
    this.useCache = true,
    this.pythonPath,
    required this.projectRoot,
  })  : cacheDir = cacheDir ?? path.join(Directory.current.path, '.analyser_cache'),
        _svgProcessor = SvgProcessor(
          pythonPath: pythonPath,
          projectRoot: projectRoot,
        ),
        _lottieProcessor = LottieProcessor(
          pythonPath: pythonPath,
          projectRoot: projectRoot,
        );

  /// Generate embeddings for all assets
  Future<Map<AssetInfo, List<double>>> generateEmbeddings(
    List<AssetInfo> assets,
  ) async {
    final embeddings = <AssetInfo, List<double>>{};

    // Prepare cache directory
    if (useCache) {
      final cache = Directory(cacheDir);
      if (!cache.existsSync()) {
        cache.createSync(recursive: true);
      }
    }

    // Process assets that need rasterization first (SVG, Lottie)
    final imagesToProcess = <AssetInfo>[];
    final processedImages = <String, String>{}; // original path -> temp image path
    final lottieFrameAssets = <AssetInfo, List<String>>{}; // Lottie assets with multiple frames

    print('Processing assets (rasterizing SVG, extracting Lottie frames)...');
    
    for (final asset in assets) {
      String imagePath;
      List<String>? framePaths;
      
      switch (asset.type) {
        case AssetType.image:
          imagePath = asset.path;
          break;
        case AssetType.svg:
          try {
            print('  Rasterizing SVG: ${asset.fileName}');
            imagePath = await _svgProcessor!.rasterizeSvg(asset.path);
            _tempFiles.add(imagePath); // Track for cleanup
          } catch (e) {
            print('  Warning: Failed to rasterize SVG ${asset.path}: $e');
            continue;
          }
          break;
        case AssetType.lottie:
          try {
            print('  Extracting Lottie frames: ${asset.fileName}');
            framePaths = await _lottieProcessor!.extractFrames(asset.path);
            if (framePaths.isEmpty) {
              print('  Warning: No frames extracted from ${asset.path}');
              continue;
            }
            _tempFiles.addAll(framePaths); // Track for cleanup
            lottieFrameAssets[asset] = framePaths;
            // Use first frame as primary image for now
            imagePath = framePaths.first;
          } catch (e) {
            print('  Warning: Failed to extract Lottie frames from ${asset.path}: $e');
            continue;
          }
          break;
      }

      imagesToProcess.add(asset);
      processedImages[asset.path] = imagePath;
    }

    // Check cache first
    final uncachedAssets = <AssetInfo>[];
    final cachedEmbeddings = <AssetInfo, List<double>>{};

    for (final asset in imagesToProcess) {
        if (useCache) {
          final cached = await _loadFromCache(asset);
          if (cached.isNotEmpty) {
            cachedEmbeddings[asset] = cached;
            continue;
          }
        }
      uncachedAssets.add(asset);
    }

    embeddings.addAll(cachedEmbeddings);

    // Generate embeddings for uncached assets
    if (uncachedAssets.isNotEmpty) {
      // Collect all image paths (including Lottie frames)
      final allImagePaths = <String>[];
      final assetToImagePaths = <AssetInfo, List<String>>{};
      
      for (final asset in uncachedAssets) {
        if (asset.type == AssetType.lottie && lottieFrameAssets.containsKey(asset)) {
          // Include all frames for Lottie
          final framePaths = lottieFrameAssets[asset]!;
          allImagePaths.addAll(framePaths);
          assetToImagePaths[asset] = framePaths;
        } else {
          // Single image path
          final imagePath = processedImages[asset.path]!;
          allImagePaths.add(imagePath);
          assetToImagePaths[asset] = [imagePath];
        }
      }

      print('Generating embeddings for ${uncachedAssets.length} assets (${allImagePaths.length} images)...');
      
      final newEmbeddings = await pythonBridge.generateEmbeddingsBatch(allImagePaths);

      // Map back to assets and cache
      for (final asset in uncachedAssets) {
        final imagePaths = assetToImagePaths[asset]!;
        List<double>? embedding;
        
        // For Lottie assets, use average of all frame embeddings
        if (asset.type == AssetType.lottie && imagePaths.length > 1) {
          final frameEmbeddings = <List<double>>[];
          
          for (final framePath in imagePaths) {
            final frameEmbedding = newEmbeddings[framePath];
            if (frameEmbedding != null && frameEmbedding.isNotEmpty) {
              frameEmbeddings.add(frameEmbedding);
            }
          }
          
          if (frameEmbeddings.isNotEmpty) {
            // Calculate average embedding
            embedding = _averageEmbeddings(frameEmbeddings);
          }
        } else {
          // Single image path
          embedding = newEmbeddings[imagePaths.first];
        }
        
        if (embedding != null && embedding.isNotEmpty) {
          embeddings[asset] = embedding;
          
          if (useCache) {
            await _saveToCache(asset, embedding);
          }
        } else {
          print('Warning: Failed to generate embedding for ${asset.path}');
        }
      }
    }

    // Clean up temporary files
    _cleanupTempFiles();

    return embeddings;
  }

  /// Calculate average of multiple embeddings
  List<double> _averageEmbeddings(List<List<double>> embeddings) {
    if (embeddings.isEmpty) return [];
    if (embeddings.length == 1) return embeddings.first;
    
    final length = embeddings.first.length;
    final averaged = List<double>.filled(length, 0.0);
    
    for (final embedding in embeddings) {
      for (int i = 0; i < length; i++) {
        averaged[i] += embedding[i];
      }
    }
    
    final count = embeddings.length.toDouble();
    for (int i = 0; i < length; i++) {
      averaged[i] /= count;
    }
    
    // Normalize the averaged embedding
    final norm = averaged.fold<double>(0.0, (sum, val) => sum + val * val);
    final normFactor = 1.0 / math.sqrt(norm);
    for (int i = 0; i < length; i++) {
      averaged[i] *= normFactor;
    }
    
    return averaged;
  }

  /// Clean up temporary files
  void _cleanupTempFiles() {
    for (final tempFile in _tempFiles) {
      try {
        final file = File(tempFile);
        if (file.existsSync()) {
          file.deleteSync();
        }
      } catch (e) {
        // Ignore cleanup errors
      }
    }
    _tempFiles.clear();
  }

  /// Load embedding from cache
  Future<List<double>> _loadFromCache(AssetInfo asset) async {
    try {
      final cacheKey = _getCacheKey(asset);
      final cacheFile = File(path.join(cacheDir, '$cacheKey.json'));
      
      if (!cacheFile.existsSync()) {
        return [];
      }

      // Check if cache is still valid (file hasn't changed)
      final cacheStat = await cacheFile.stat();
      if (asset.lastModified != null &&
          cacheStat.modified.isBefore(asset.lastModified!)) {
        // Cache is stale
        return [];
      }

      final content = await cacheFile.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      final embedding = (json['embedding'] as List)
          .map((e) => (e as num).toDouble())
          .toList();

      return embedding;
    } catch (_) {
      return [];
    }
  }

  /// Save embedding to cache
  Future<void> _saveToCache(AssetInfo asset, List<double> embedding) async {
    try {
      final cacheKey = _getCacheKey(asset);
      final cacheFile = File(path.join(cacheDir, '$cacheKey.json'));
      
      final json = jsonEncode({
        'path': asset.path,
        'embedding': embedding,
        'timestamp': DateTime.now().toIso8601String(),
      });

      await cacheFile.writeAsString(json);
    } catch (e) {
      print('Warning: Failed to cache embedding for ${asset.path}: $e');
    }
  }

  /// Generate cache key for asset
  String _getCacheKey(AssetInfo asset) {
    // Use file path hash as cache key
    final hash = asset.path.hashCode.toRadixString(16);
    return hash;
  }
}

