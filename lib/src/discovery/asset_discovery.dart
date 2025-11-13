import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart' show loadYaml;
import '../models/asset_info.dart';

/// Discovers assets in a Flutter project
class AssetDiscovery {
  final String projectRoot;
  final Set<AssetType> allowedTypes;
  final String? excludePattern;

  AssetDiscovery({
    required this.projectRoot,
    Set<AssetType>? allowedTypes,
    this.excludePattern,
  }) : allowedTypes = allowedTypes ?? AssetType.values.toSet();

  /// Discover all assets in the project
  Future<List<AssetInfo>> discoverAssets() async {
    final assets = <AssetInfo>[];

    // 1. Find assets from pubspec.yaml
    final pubspecAssets = await _discoverFromPubspec();
    assets.addAll(pubspecAssets);

    // 2. Find assets from assets/ folder (common convention)
    final folderAssets = await _discoverFromAssetsFolder();
    assets.addAll(folderAssets);

    // Remove duplicates
    final uniqueAssets = <String, AssetInfo>{};
    for (final asset in assets) {
      final normalizedPath = path.normalize(asset.path);
      if (!uniqueAssets.containsKey(normalizedPath)) {
        uniqueAssets[normalizedPath] = asset;
      }
    }

    return uniqueAssets.values.toList();
  }

  /// Discover assets from pubspec.yaml
  Future<List<AssetInfo>> _discoverFromPubspec() async {
    final pubspecPath = path.join(projectRoot, 'pubspec.yaml');
    final pubspecFile = File(pubspecPath);

    if (!pubspecFile.existsSync()) {
      return [];
    }

    try {
      final content = await pubspecFile.readAsString();
      final yaml = loadYaml(content);
      final flutter = yaml['flutter'];
      if (flutter == null) return [];

      final assets = flutter['assets'];
      if (assets == null) return [];

      final assetList = <AssetInfo>[];

      for (final asset in assets) {
        if (asset is! String) continue;

        // Handle directory patterns (e.g., "assets/")
        if (asset.endsWith('/')) {
          final dirAssets = await _discoverFromDirectory(asset);
          assetList.addAll(dirAssets);
        } else {
          // Single file
          final assetPath = path.join(projectRoot, asset);
          final file = File(assetPath);
          if (file.existsSync()) {
            final assetInfo = await _createAssetInfo(assetPath, asset);
            if (assetInfo != null) {
              assetList.add(assetInfo);
            }
          }
        }
      }

      return assetList;
    } catch (e) {
      print('Warning: Failed to parse pubspec.yaml: $e');
      return [];
    }
  }

  /// Discover assets from assets/ folder
  Future<List<AssetInfo>> _discoverFromAssetsFolder() async {
    final assetsDir = Directory(path.join(projectRoot, 'assets'));
    if (!assetsDir.existsSync()) {
      return [];
    }

    return _discoverFromDirectory('assets/');
  }

  /// Discover assets from a directory
  Future<List<AssetInfo>> _discoverFromDirectory(String dirPath) async {
    final fullPath = path.join(projectRoot, dirPath);
    final directory = Directory(fullPath);

    if (!directory.existsSync()) {
      return [];
    }

    final assets = <AssetInfo>[];

    await for (final entity in directory.list(recursive: true)) {
      if (entity is File) {
        final relativePath = path.relative(entity.path, from: projectRoot);
        
        // Check exclude pattern
        if (excludePattern != null && _matchesPattern(relativePath, excludePattern!)) {
          continue;
        }

        final assetInfo = await _createAssetInfo(entity.path, relativePath);
        if (assetInfo != null && allowedTypes.contains(assetInfo.type)) {
          assets.add(assetInfo);
        }
      }
    }

    return assets;
  }

  /// Create AssetInfo from file path
  Future<AssetInfo?> _createAssetInfo(String fullPath, String relativePath) async {
    final file = File(fullPath);
    if (!file.existsSync()) return null;

    final ext = path.extension(fullPath).replaceFirst('.', '');
    final type = AssetTypeExtension.fromExtension(ext);
    
    if (type == null) return null;
    if (!allowedTypes.contains(type)) return null;

    // Check if it's a Lottie file (JSON with Lottie structure)
    if (type == AssetType.lottie) {
      final isLottie = await _isLottieFile(fullPath);
      if (!isLottie) return null;
    }

    final stat = await file.stat();
    final lastModified = stat.modified;

    return AssetInfo(
      path: fullPath,
      relativePath: relativePath,
      type: type,
      sizeBytes: stat.size,
      lastModified: lastModified,
    );
  }

  /// Check if JSON file is a Lottie animation
  Future<bool> _isLottieFile(String filePath) async {
    try {
      final content = await File(filePath).readAsString();
      // Basic check: Lottie files typically have "v", "fr", "ip", "op" keys
      return content.contains('"v"') &&
          content.contains('"fr"') &&
          (content.contains('"ip"') || content.contains('"op"'));
    } catch (_) {
      return false;
    }
  }

  /// Check if path matches glob pattern (simple implementation)
  bool _matchesPattern(String path, String pattern) {
    // Simple glob matching - can be enhanced
    if (pattern.contains('*')) {
      final regexPattern = pattern
          .replaceAll('.', r'\.')
          .replaceAll('*', '.*');
      final regex = RegExp(regexPattern);
      return regex.hasMatch(path);
    }
    return path.contains(pattern);
  }
}

