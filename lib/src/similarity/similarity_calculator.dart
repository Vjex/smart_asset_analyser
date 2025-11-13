import 'dart:math';
import '../models/asset_info.dart';
import '../models/similarity_group.dart';

/// Calculates similarity between embeddings
class SimilarityCalculator {
  /// Calculate cosine similarity between two embeddings
  /// Returns value between -1.0 and 1.0 (typically 0.0 to 1.0 for normalized embeddings)
  static double cosineSimilarity(List<double> embedding1, List<double> embedding2) {
    if (embedding1.length != embedding2.length) {
      throw ArgumentError('Embeddings must have the same length');
    }

    double dotProduct = 0.0;
    double norm1 = 0.0;
    double norm2 = 0.0;

    for (int i = 0; i < embedding1.length; i++) {
      dotProduct += embedding1[i] * embedding2[i];
      norm1 += embedding1[i] * embedding1[i];
      norm2 += embedding2[i] * embedding2[i];
    }

    final denominator = sqrt(norm1) * sqrt(norm2);
    if (denominator == 0.0) {
      return 0.0;
    }

    return dotProduct / denominator;
  }

  /// Find similar asset pairs above threshold
  static List<AssetPair> findSimilarPairs(
    Map<AssetInfo, List<double>> embeddings,
    double threshold,
  ) {
    final pairs = <AssetPair>[];
    final assets = embeddings.keys.toList();

    for (int i = 0; i < assets.length; i++) {
      for (int j = i + 1; j < assets.length; j++) {
        final asset1 = assets[i];
        final asset2 = assets[j];
        final embedding1 = embeddings[asset1]!;
        final embedding2 = embeddings[asset2]!;

        final similarity = cosineSimilarity(embedding1, embedding2);

        if (similarity >= threshold) {
          pairs.add(AssetPair(
            asset1: asset1,
            asset2: asset2,
            similarity: similarity,
          ));
        }
      }
    }

    return pairs;
  }

  /// Group similar assets into clusters
  static List<SimilarityGroup> groupSimilarAssets(
    List<AssetPair> pairs,
  ) {
    // Use union-find to group connected assets
    final groups = <Set<AssetInfo>>[];
    final assetToGroup = <AssetInfo, int>{};

    for (final pair in pairs) {
      final group1Index = assetToGroup[pair.asset1];
      final group2Index = assetToGroup[pair.asset2];

      if (group1Index == null && group2Index == null) {
        // Create new group
        final newGroup = {pair.asset1, pair.asset2};
        final newIndex = groups.length;
        groups.add(newGroup);
        assetToGroup[pair.asset1] = newIndex;
        assetToGroup[pair.asset2] = newIndex;
      } else if (group1Index != null && group2Index == null) {
        // Add asset2 to group1
        final idx1 = group1Index;
        groups[idx1].add(pair.asset2);
        assetToGroup[pair.asset2] = idx1;
      } else if (group1Index == null && group2Index != null) {
        // Add asset1 to group2
        final idx2 = group2Index;
        groups[idx2].add(pair.asset1);
        assetToGroup[pair.asset1] = idx2;
      } else if (group1Index != null && group2Index != null && group1Index != group2Index) {
        // Merge two groups
        final idx1 = group1Index;
        final idx2 = group2Index;
        final group1 = groups[idx1];
        final group2 = groups[idx2];
        group1.addAll(group2);
        for (final asset in group2) {
          assetToGroup[asset] = idx1;
        }
        groups[idx2] = <AssetInfo>{}; // Mark as merged
      }
    }

    // Build SimilarityGroup objects
    final similarityGroups = <SimilarityGroup>[];
    for (final group in groups) {
      if (group.isEmpty) continue;

      // Find all pairs within this group
      final groupPairs = pairs.where((pair) {
        return group.contains(pair.asset1) && group.contains(pair.asset2);
      }).toList();

      if (groupPairs.isNotEmpty) {
        similarityGroups.add(SimilarityGroup(groupPairs));
      }
    }

    // Sort by average similarity (descending)
    similarityGroups.sort((a, b) =>
        b.averageSimilarity.compareTo(a.averageSimilarity));

    return similarityGroups;
  }
}

