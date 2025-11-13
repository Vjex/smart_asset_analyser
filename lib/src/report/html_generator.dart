import 'dart:convert';
import 'package:path/path.dart' as path;
import '../models/asset_info.dart';
import '../models/similarity_group.dart';

/// Generates HTML report for asset analysis
class HtmlGenerator {
  final String projectRoot;

  HtmlGenerator({required this.projectRoot});

  /// Generate HTML report
  String generateReport({
    required List<AssetInfo> assets,
    required List<SimilarityGroup> groups,
    required double threshold,
    required int minSimilarity,
  }) {
    final groupsJson = jsonEncode(groups.map((g) => _groupToJson(g)).toList());
    final assetsJson = jsonEncode(assets.map((a) => _assetToJson(a)).toList());

    return '''
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Flutter Asset Analyser Report</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
            background: #f5f5f5;
            color: #333;
            line-height: 1.6;
        }
        
        .header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 2rem;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        
        .header h1 {
            font-size: 2rem;
            margin-bottom: 0.5rem;
        }
        
        .header p {
            opacity: 0.9;
        }
        
        .container {
            max-width: 1400px;
            margin: 0 auto;
            padding: 2rem;
        }
        
        .stats {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 1rem;
            margin-bottom: 2rem;
        }
        
        .stat-card {
            background: white;
            padding: 1.5rem;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        
        .stat-card h3 {
            font-size: 0.9rem;
            color: #666;
            margin-bottom: 0.5rem;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }
        
        .stat-card .value {
            font-size: 2rem;
            font-weight: bold;
            color: #667eea;
        }
        
        .filters {
            background: white;
            padding: 1.5rem;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
            margin-bottom: 2rem;
        }
        
        .filters h2 {
            font-size: 1.2rem;
            margin-bottom: 1rem;
        }
        
        .filter-group {
            display: flex;
            gap: 2rem;
            flex-wrap: wrap;
            align-items: center;
        }
        
        .filter-item {
            display: flex;
            flex-direction: column;
            gap: 0.5rem;
        }
        
        .filter-item label {
            font-size: 0.9rem;
            font-weight: 500;
            color: #666;
        }
        
        .slider {
            width: 200px;
        }
        
        .slider-value {
            font-weight: bold;
            color: #667eea;
        }
        
        .type-filters {
            display: flex;
            gap: 1rem;
        }
        
        .type-filter {
            display: flex;
            align-items: center;
            gap: 0.5rem;
        }
        
        .type-filter input[type="checkbox"] {
            width: 18px;
            height: 18px;
            cursor: pointer;
        }
        
        .search-box {
            padding: 0.5rem;
            border: 2px solid #ddd;
            border-radius: 4px;
            font-size: 1rem;
            width: 300px;
        }
        
        .search-box:focus {
            outline: none;
            border-color: #667eea;
        }
        
        .groups {
            display: flex;
            flex-direction: column;
            gap: 2rem;
        }
        
        .group {
            background: white;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
            overflow: hidden;
        }
        
        .group-header {
            background: #f8f9fa;
            padding: 1rem 1.5rem;
            border-bottom: 2px solid #e9ecef;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        
        .group-header h3 {
            font-size: 1.1rem;
        }
        
        .similarity-badge {
            background: #667eea;
            color: white;
            padding: 0.25rem 0.75rem;
            border-radius: 20px;
            font-size: 0.9rem;
            font-weight: bold;
        }
        
        .group-content {
            padding: 1.5rem;
        }
        
        .assets-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
            gap: 1.5rem;
        }
        
        .asset-card {
            border: 2px solid #e9ecef;
            border-radius: 8px;
            overflow: hidden;
            transition: transform 0.2s, box-shadow 0.2s;
            cursor: pointer;
        }
        
        .asset-card:hover {
            transform: translateY(-2px);
            box-shadow: 0 4px 12px rgba(0,0,0,0.15);
        }
        
        .asset-preview {
            width: 100%;
            height: 150px;
            object-fit: contain;
            background: #f8f9fa;
            padding: 0.5rem;
        }
        
        .asset-info {
            padding: 1rem;
        }
        
        .asset-name {
            font-weight: bold;
            margin-bottom: 0.25rem;
            word-break: break-all;
            font-size: 0.9rem;
        }
        
        .asset-path {
            font-size: 0.8rem;
            color: #666;
            margin-bottom: 0.5rem;
        }
        
        .asset-size {
            font-size: 0.8rem;
            color: #999;
        }
        
        .pair-comparison {
            display: flex;
            gap: 1rem;
            margin-bottom: 1rem;
            padding: 1rem;
            background: #f8f9fa;
            border-radius: 8px;
        }
        
        .pair-item {
            flex: 1;
            text-align: center;
        }
        
        .pair-similarity {
            font-size: 1.2rem;
            font-weight: bold;
            color: #667eea;
            margin: 0.5rem 0;
        }
        
        .no-results {
            text-align: center;
            padding: 3rem;
            color: #999;
        }
        
        .hidden {
            display: none !important;
        }
    </style>
</head>
<body>
    <div class="header">
        <div class="container">
            <h1>🔍 Flutter Asset Analyser</h1>
            <p>Visual Similarity Report</p>
        </div>
    </div>
    
    <div class="container">
        <div class="stats">
            <div class="stat-card">
                <h3>Total Assets</h3>
                <div class="value" id="stat-total">${assets.length}</div>
            </div>
            <div class="stat-card">
                <h3>Similarity Groups</h3>
                <div class="value" id="stat-groups">${groups.length}</div>
            </div>
            <div class="stat-card">
                <h3>Similar Pairs</h3>
                <div class="value" id="stat-pairs">${groups.fold<int>(0, (sum, g) => sum + g.pairs.length)}</div>
            </div>
            <div class="stat-card">
                <h3>Min Similarity</h3>
                <div class="value">${minSimilarity}%</div>
            </div>
        </div>
        
        <div class="filters">
            <h2>Filters</h2>
            <div class="filter-group">
                <div class="filter-item">
                    <label>Similarity: <span class="slider-value" id="similarity-value">${minSimilarity}%</span></label>
                    <input type="range" min="0" max="100" value="${minSimilarity}" class="slider" id="similarity-slider">
                </div>
                
                <div class="filter-item">
                    <label>Asset Types</label>
                    <div class="type-filters">
                        <div class="type-filter">
                            <input type="checkbox" id="filter-images" checked>
                            <label for="filter-images">Images</label>
                        </div>
                        <div class="type-filter">
                            <input type="checkbox" id="filter-svgs" checked>
                            <label for="filter-svgs">SVGs</label>
                        </div>
                        <div class="type-filter">
                            <input type="checkbox" id="filter-lottie" checked>
                            <label for="filter-lottie">Lottie</label>
                        </div>
                    </div>
                </div>
                
                <div class="filter-item">
                    <label>Search</label>
                    <input type="text" class="search-box" id="search-box" placeholder="Search by filename...">
                </div>
            </div>
        </div>
        
        <div class="groups" id="groups-container">
            ${_generateGroupsHtml(groups)}
        </div>
        
        <div class="no-results hidden" id="no-results">
            <h2>No results found</h2>
            <p>Try adjusting your filters</p>
        </div>
    </div>
    
    <script>
        const groupsData = $groupsJson;
        const assetsData = $assetsJson;
        
        function updateFilters() {
            const similarityThreshold = parseInt(document.getElementById('similarity-slider').value);
            const showImages = document.getElementById('filter-images').checked;
            const showSvgs = document.getElementById('filter-svgs').checked;
            const showLottie = document.getElementById('filter-lottie').checked;
            const searchTerm = document.getElementById('search-box').value.toLowerCase();
            
            document.getElementById('similarity-value').textContent = similarityThreshold + '%';
            
            const groups = document.querySelectorAll('.group');
            let visibleCount = 0;
            
            groups.forEach(group => {
                const groupData = JSON.parse(group.dataset.group);
                const avgSimilarity = Math.round(groupData.averageSimilarity * 100);
                const groupTypes = new Set(groupData.assets.map(a => a.type));
                
                // Check similarity threshold
                if (avgSimilarity < similarityThreshold) {
                    group.classList.add('hidden');
                    return;
                }
                
                // Check type filters
                const hasImage = groupTypes.has('image') && showImages;
                const hasSvg = groupTypes.has('svg') && showSvgs;
                const hasLottie = groupTypes.has('lottie') && showLottie;
                
                if (!hasImage && !hasSvg && !hasLottie) {
                    group.classList.add('hidden');
                    return;
                }
                
                // Check search term
                if (searchTerm) {
                    const matches = groupData.assets.some(asset => 
                        asset.fileName.toLowerCase().includes(searchTerm) ||
                        asset.relativePath.toLowerCase().includes(searchTerm)
                    );
                    if (!matches) {
                        group.classList.add('hidden');
                        return;
                    }
                }
                
                group.classList.remove('hidden');
                visibleCount++;
            });
            
            document.getElementById('no-results').classList.toggle('hidden', visibleCount > 0);
            document.getElementById('stat-groups').textContent = visibleCount;
        }
        
        // Event listeners
        document.getElementById('similarity-slider').addEventListener('input', updateFilters);
        document.getElementById('filter-images').addEventListener('change', updateFilters);
        document.getElementById('filter-svgs').addEventListener('change', updateFilters);
        document.getElementById('filter-lottie').addEventListener('change', updateFilters);
        document.getElementById('search-box').addEventListener('input', updateFilters);
        
        // Asset card click handler (for future: open full-size view)
        document.querySelectorAll('.asset-card').forEach(card => {
            card.addEventListener('click', function() {
                const path = this.dataset.path;
                console.log('Clicked asset:', path);
                // TODO: Open modal with full-size image
            });
        });
    </script>
</body>
</html>
'''.replaceAll('\$groupsJson', groupsJson).replaceAll('\$assetsJson', assetsJson);
  }

  String _generateGroupsHtml(List<SimilarityGroup> groups) {
    if (groups.isEmpty) {
      return '<div class="no-results"><h2>No similar assets found</h2></div>';
    }

    final buffer = StringBuffer();
    
    for (final group in groups) {
      final avgSimilarity = (group.averageSimilarity * 100).round();
      final groupJson = jsonEncode(_groupToJson(group));
      
      buffer.writeln('<div class="group" data-group="${groupJson.replaceAll('"', '&quot;')}">');
      buffer.writeln('  <div class="group-header">');
      buffer.writeln('    <h3>Group with ${group.assetCount} assets</h3>');
      buffer.writeln('    <span class="similarity-badge">${avgSimilarity}% similar</span>');
      buffer.writeln('  </div>');
      buffer.writeln('  <div class="group-content">');
      
      // Show pairs
      if (group.pairs.length <= 5) {
        for (final pair in group.pairs) {
          buffer.writeln('    <div class="pair-comparison">');
          buffer.writeln('      <div class="pair-item">');
          buffer.writeln('        <div class="asset-name">${_escapeHtml(pair.asset1.fileName)}</div>');
          buffer.writeln('        <div class="asset-path">${_escapeHtml(pair.asset1.relativePath)}</div>');
          buffer.writeln('      </div>');
          buffer.writeln('      <div class="pair-similarity">${pair.similarityPercentage}%</div>');
          buffer.writeln('      <div class="pair-item">');
          buffer.writeln('        <div class="asset-name">${_escapeHtml(pair.asset2.fileName)}</div>');
          buffer.writeln('        <div class="asset-path">${_escapeHtml(pair.asset2.relativePath)}</div>');
          buffer.writeln('      </div>');
          buffer.writeln('    </div>');
        }
      }
      
      // Show all assets in grid
      buffer.writeln('    <div class="assets-grid">');
      for (final asset in group.assets) {
        final assetPath = _getAssetUrl(asset);
        buffer.writeln('      <div class="asset-card" data-path="${_escapeHtml(asset.path)}">');
        buffer.writeln('        <img src="${_escapeHtml(assetPath)}" alt="${_escapeHtml(asset.fileName)}" class="asset-preview" onerror="this.style.display=\'none\'">');
        buffer.writeln('        <div class="asset-info">');
        buffer.writeln('          <div class="asset-name">${_escapeHtml(asset.fileName)}</div>');
        buffer.writeln('          <div class="asset-path">${_escapeHtml(asset.relativePath)}</div>');
        buffer.writeln('          <div class="asset-size">${_formatSize(asset.sizeBytes)}</div>');
        buffer.writeln('        </div>');
        buffer.writeln('      </div>');
      }
      buffer.writeln('    </div>');
      
      buffer.writeln('  </div>');
      buffer.writeln('</div>');
    }
    
    return buffer.toString();
  }

  Map<String, dynamic> _groupToJson(SimilarityGroup group) {
    return {
      'averageSimilarity': group.averageSimilarity,
      'minSimilarity': group.minSimilarity,
      'maxSimilarity': group.maxSimilarity,
      'assetCount': group.assetCount,
      'pairs': group.pairs.map((p) => {
        'asset1': _assetToJson(p.asset1),
        'asset2': _assetToJson(p.asset2),
        'similarity': p.similarity,
        'similarityPercentage': p.similarityPercentage,
      }).toList(),
      'assets': group.assets.map((a) => _assetToJson(a)).toList(),
    };
  }

  Map<String, dynamic> _assetToJson(AssetInfo asset) {
    return {
      'path': asset.path,
      'relativePath': asset.relativePath,
      'fileName': asset.fileName,
      'type': asset.type.name,
      'sizeBytes': asset.sizeBytes,
      'extension': asset.extension,
    };
  }

  String _getAssetUrl(AssetInfo asset) {
    // Convert absolute path to relative path for HTML
    final relative = path.relative(asset.path, from: projectRoot);
    return relative.replaceAll('\\', '/');
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  String _escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }
}

