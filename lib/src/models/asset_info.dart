import 'dart:io';

/// Asset information model
class AssetInfo {
  final String path;
  final String relativePath;
  final AssetType type;
  final int sizeBytes;
  final String? embeddingCacheKey;
  final DateTime? lastModified;

  AssetInfo({
    required this.path,
    required this.relativePath,
    required this.type,
    required this.sizeBytes,
    this.embeddingCacheKey,
    this.lastModified,
  });

  String get extension {
    final parts = path.split('.');
    return parts.length > 1 ? parts.last.toLowerCase() : '';
  }

  String get fileName {
    return path.split(Platform.pathSeparator).last;
  }

  @override
  String toString() => 'AssetInfo(path: $relativePath, type: $type, size: $sizeBytes)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AssetInfo &&
          runtimeType == other.runtimeType &&
          path == other.path;

  @override
  int get hashCode => path.hashCode;
}

enum AssetType {
  image,
  svg,
  lottie,
}

extension AssetTypeExtension on AssetType {
  String get name {
    switch (this) {
      case AssetType.image:
        return 'Images';
      case AssetType.svg:
        return 'SVGs';
      case AssetType.lottie:
        return 'Lottie';
    }
  }

  static AssetType? fromExtension(String ext) {
    final lowerExt = ext.toLowerCase();
    if (['png', 'jpg', 'jpeg', 'webp', 'gif', 'bmp'].contains(lowerExt)) {
      return AssetType.image;
    } else if (lowerExt == 'svg') {
      return AssetType.svg;
    } else if (lowerExt == 'json') {
      // Lottie files are JSON, but we'll need to check content
      return AssetType.lottie;
    }
    return null;
  }
}

