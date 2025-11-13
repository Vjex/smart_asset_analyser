import 'asset_info.dart';

/// A group of similar assets
class SimilarityGroup {
  final List<AssetPair> pairs;
  final Set<AssetInfo> assets;

  SimilarityGroup(this.pairs) : assets = _extractAssets(pairs);

  static Set<AssetInfo> _extractAssets(List<AssetPair> pairs) {
    final assetSet = <AssetInfo>{};
    for (final pair in pairs) {
      assetSet.add(pair.asset1);
      assetSet.add(pair.asset2);
    }
    return assetSet;
  }

  /// Average similarity score in the group
  double get averageSimilarity {
    if (pairs.isEmpty) return 0.0;
    final sum = pairs.fold<double>(0.0, (sum, pair) => sum + pair.similarity);
    return sum / pairs.length;
  }

  /// Minimum similarity score in the group
  double get minSimilarity {
    if (pairs.isEmpty) return 0.0;
    return pairs.map((p) => p.similarity).reduce((a, b) => a < b ? a : b);
  }

  /// Maximum similarity score in the group
  double get maxSimilarity {
    if (pairs.isEmpty) return 0.0;
    return pairs.map((p) => p.similarity).reduce((a, b) => a > b ? a : b);
  }

  int get assetCount => assets.length;

  @override
  String toString() =>
      'SimilarityGroup(assets: $assetCount, avgSimilarity: ${averageSimilarity.toStringAsFixed(2)})';
}

/// A pair of similar assets with their similarity score
class AssetPair {
  final AssetInfo asset1;
  final AssetInfo asset2;
  final double similarity; // 0.0 to 1.0

  AssetPair({
    required this.asset1,
    required this.asset2,
    required this.similarity,
  });

  /// Similarity as percentage (0-100)
  int get similarityPercentage => (similarity * 100).round();

  @override
  String toString() =>
      'AssetPair(${asset1.fileName} <-> ${asset2.fileName}, ${similarityPercentage}%)';
}

