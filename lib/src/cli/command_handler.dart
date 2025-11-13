import 'dart:io';
import 'package:args/args.dart';
import 'package:path/path.dart' as path;
import '../discovery/asset_discovery.dart';
import '../models/asset_info.dart';
import '../embeddings/embedding_service.dart';
import '../embeddings/python_bridge.dart';
import '../similarity/similarity_calculator.dart';
import '../report/html_generator.dart';

/// Handles CLI commands
class CommandHandler {
  Future<void> handleAnalyseAssets(ArgResults args) async {
    print('🔍 Flutter Asset Analyser');
    print('');

    // Parse arguments
    final projectPath = path.normalize(args['project-path'] as String);
    final threshold = double.tryParse(args['threshold'] as String) ?? 0.85;
    final minSimilarity = int.tryParse(args['min-similarity'] as String) ?? 85;
    final outputPath = args['output'] as String;
    final typesStr = args['types'] as String;
    final excludePattern = args['exclude'] as String?;
    final pythonPath = args['python-path'] as String?;
    final useServer = args['use-server'] as bool;
    final serverPort = int.tryParse(args['server-port'] as String) ?? 8000;
    final cacheEmbeddings = args['cache-embeddings'] as bool;

    // Parse asset types
    final allowedTypes = <AssetType>{};
    if (typesStr == 'all') {
      allowedTypes.addAll(AssetType.values);
    } else {
      final typeList = typesStr.split(',');
      for (final typeStr in typeList) {
        switch (typeStr.trim().toLowerCase()) {
          case 'images':
            allowedTypes.add(AssetType.image);
            break;
          case 'svgs':
            allowedTypes.add(AssetType.svg);
            break;
          case 'lottie':
            allowedTypes.add(AssetType.lottie);
            break;
        }
      }
    }

    // Validate project path
    final projectDir = Directory(projectPath);
    if (!projectDir.existsSync()) {
      print('Error: Project path does not exist: $projectPath');
      exit(1);
    }

    print('Project: $projectPath');
    print('Threshold: $threshold (${minSimilarity}%)');
    print('Types: ${allowedTypes.map((t) => t.name).join(", ")}');
    print('');

    // Initialize Python bridge
    print('Checking Python CLIP service...');
    final pythonBridge = PythonBridge(
      pythonPath: pythonPath,
      useServer: useServer,
      serverPort: serverPort,
      projectRoot: projectPath,
    );

    // Check Python dependencies
    final hasDeps = await pythonBridge.checkDependencies();
    if (!hasDeps) {
      final pipCommand = PythonBridge.getPipCommand();
      
      print('');
      print('⚠️  Python dependencies not found!');
      print('');
      
      // Try to find requirements.txt
      final requirementsPath = await pythonBridge.getRequirementsTxtPath();
      if (requirementsPath != null) {
        print('📄 Found requirements.txt at:');
        print('   $requirementsPath');
        print('');
        print('✅ Install Python dependencies with:');
        if (pipCommand.contains(' -m ')) {
          print('   $pipCommand install -r "$requirementsPath"');
        } else {
          print('   $pipCommand install -r "$requirementsPath"');
        }
      } else {
        final packageLocation = await pythonBridge.getPackageLocation();
        print('📦 Package location: $packageLocation');
        if (packageLocation != 'unknown') {
          final altPath = path.join(packageLocation, 'requirements.txt');
          print('📄 Try: $altPath');
        }
        print('');
        print('✅ Install Python dependencies:');
        if (pipCommand.contains(' -m ')) {
          print('   $pipCommand install torch transformers pillow numpy cairosvg lottie');
        } else {
          print('   $pipCommand install torch transformers pillow numpy cairosvg lottie');
        }
        print('');
        print('Or find requirements.txt in the package directory and run:');
        if (pipCommand.contains(' -m ')) {
          print('   $pipCommand install -r <path-to-package>/requirements.txt');
        } else {
          print('   $pipCommand install -r <path-to-package>/requirements.txt');
        }
      }
      print('');
      print('After installing, run the command again.');
      exit(1);
    }
    print('✓ Python CLIP service ready');
    print('');

    // Discover assets
    print('Discovering assets...');
    final discovery = AssetDiscovery(
      projectRoot: projectPath,
      allowedTypes: allowedTypes,
      excludePattern: excludePattern,
    );

    final assets = await discovery.discoverAssets();
    print('Found ${assets.length} assets');
    print('');

    if (assets.isEmpty) {
      print('No assets found. Exiting.');
      exit(0);
    }

    // Generate embeddings
    final embeddingService = EmbeddingService(
      pythonBridge: pythonBridge,
      useCache: cacheEmbeddings,
      pythonPath: pythonPath,
      projectRoot: projectPath,
    );

    print('Generating embeddings...');
    final embeddings = await embeddingService.generateEmbeddings(assets);
    print('Generated ${embeddings.length} embeddings');
    print('');

    // Calculate similarity
    print('Calculating similarities...');
    final pairs = SimilarityCalculator.findSimilarPairs(embeddings, threshold);
    print('Found ${pairs.length} similar pairs');
    print('');

    // Group similar assets
    print('Grouping similar assets...');
    final groups = SimilarityCalculator.groupSimilarAssets(pairs);
    print('Found ${groups.length} similarity groups');
    print('');

    // Filter by minimum similarity percentage
    final filteredGroups = groups.where((group) {
      return (group.averageSimilarity * 100).round() >= minSimilarity;
    }).toList();

    print('Groups above ${minSimilarity}% similarity: ${filteredGroups.length}');
    print('');

    // Generate HTML report
    print('Generating HTML report...');
    final htmlGenerator = HtmlGenerator(
      projectRoot: projectPath,
    );

    final html = htmlGenerator.generateReport(
      assets: assets,
      groups: filteredGroups,
      threshold: threshold,
      minSimilarity: minSimilarity,
    );

    // Write report
    final outputFile = File(outputPath);
    await outputFile.writeAsString(html);
    print('✓ Report generated: $outputPath');
    print('');

    // Print summary
    print('Summary:');
    print('  Total assets: ${assets.length}');
    print('  Similar pairs: ${pairs.length}');
    print('  Similarity groups: ${filteredGroups.length}');
    if (filteredGroups.isNotEmpty) {
      final totalDuplicateSize = filteredGroups.fold<int>(
        0,
        (sum, group) {
          final groupAssets = group.assets.toList();
          // Estimate: if we keep one asset per group, we can delete the rest
          if (groupAssets.length > 1) {
            final sizes = groupAssets.map((a) => a.sizeBytes).toList()..sort();
            // Sum all but the largest (assuming we keep the largest)
            final deletableSize = sizes.sublist(0, sizes.length - 1)
                .fold<int>(0, (s, size) => s + size);
            return sum + deletableSize;
          }
          return sum;
        },
      );
      final mbSaved = (totalDuplicateSize / (1024 * 1024)).toStringAsFixed(2);
      print('  Potential space savings: ${mbSaved} MB');
    }
    print('');
    print('Done! Open $outputPath in your browser to view the report.');
  }
}

