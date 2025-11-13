import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path;
import 'package:package_config/package_config.dart';

/// Python CLIP Bridge
/// 
/// Communicates with Python CLIP service to generate embeddings.
class PythonBridge {
  final String? pythonPath;
  final bool useServer;
  final int serverPort;
  final String projectRoot;

  PythonBridge({
    this.pythonPath,
    this.useServer = false,
    this.serverPort = 8000,
    required this.projectRoot,
  });

  /// Get Python executable path
  String get _pythonExecutable {
    if (pythonPath != null) return pythonPath!;
    
    // Try common Python executables
    final candidates = ['python3', 'python'];
    for (final candidate in candidates) {
      try {
        final result = Process.runSync('which', [candidate]);
        if (result.exitCode == 0) {
          return candidate;
        }
      } catch (_) {
        // Continue to next candidate
      }
    }
    
    throw Exception(
      'Python not found. Please install Python 3.8+ and ensure it\'s in PATH, '
      'or specify --python-path option.'
    );
  }

  /// Get path to clip_service.py
  Future<String> get _clipServicePath async {
    // First, try to find via package_config (works when installed from pub.dev)
    try {
      final packageConfigFile = File(path.join(Directory.current.path, '.dart_tool', 'package_config.json'));
      if (packageConfigFile.existsSync()) {
        final packageConfig = await loadPackageConfig(packageConfigFile);
        final package = packageConfig.packages.firstWhere(
          (p) => p.name == 'smart_asset_analyser',
          orElse: () => throw StateError('Package not found'),
        );
        final packageRoot = package.root.toFilePath();
        final scriptPath = path.join(packageRoot, 'python', 'clip_service.py');
        if (File(scriptPath).existsSync()) {
          return scriptPath;
        }
      }
    } catch (_) {
      // Fall through to other methods
    }
    
    // Try relative to current script (works in development)
    try {
      final scriptPath = path.join(
        path.dirname(Platform.script.toFilePath()),
        '..',
        'python',
        'clip_service.py',
      );
      final normalized = path.normalize(scriptPath);
      if (File(normalized).existsSync()) {
        return normalized;
      }
    } catch (_) {
      // Fall through
    }
    
    // Try relative to project root (fallback)
    final altPath = path.join(projectRoot, 'python', 'clip_service.py');
    if (File(altPath).existsSync()) {
      return altPath;
    }
    
    throw Exception(
      'clip_service.py not found. Please ensure python/clip_service.py exists in the package.\n'
      'If installed from pub.dev, the Python scripts should be bundled with the package.\n'
      'Package location: ${await _getPackageLocation()}'
    );
  }

  /// Get package location for debugging
  Future<String> _getPackageLocation() async {
    try {
      final packageConfigFile = File(path.join(Directory.current.path, '.dart_tool', 'package_config.json'));
      if (packageConfigFile.existsSync()) {
        final packageConfig = await loadPackageConfig(packageConfigFile);
        final package = packageConfig.packages.firstWhere(
          (p) => p.name == 'smart_asset_analyser',
          orElse: () => throw StateError('Package not found'),
        );
        return package.root.toFilePath();
      }
    } catch (_) {
      // Ignore
    }
    return 'unknown';
  }

  /// Get package location (public method)
  Future<String> getPackageLocation() => _getPackageLocation();

  /// Check if Python dependencies are installed
  Future<bool> checkDependencies() async {
    try {
      final result = await Process.run(
        _pythonExecutable,
        ['-c', 'import torch, clip, PIL; print("OK")'],
      );
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  /// Get path to requirements.txt file
  Future<String?> getRequirementsTxtPath() async {
    // Try to find via package_config (works when installed from pub.dev)
    try {
      final packageConfigFile = File(path.join(Directory.current.path, '.dart_tool', 'package_config.json'));
      if (packageConfigFile.existsSync()) {
        final packageConfig = await loadPackageConfig(packageConfigFile);
        final package = packageConfig.packages.firstWhere(
          (p) => p.name == 'smart_asset_analyser',
          orElse: () => throw StateError('Package not found'),
        );
        final packageRoot = package.root.toFilePath();
        final requirementsPath = path.join(packageRoot, 'requirements.txt');
        if (File(requirementsPath).existsSync()) {
          return requirementsPath;
        }
      }
    } catch (_) {
      // Fall through
    }
    
    // Try relative to current script (development)
    try {
      final scriptPath = path.join(
        path.dirname(Platform.script.toFilePath()),
        '..',
        'requirements.txt',
      );
      final normalized = path.normalize(scriptPath);
      if (File(normalized).existsSync()) {
        return normalized;
      }
    } catch (_) {
      // Fall through
    }
    
    // Try relative to project root
    final altPath = path.join(projectRoot, 'requirements.txt');
    if (File(altPath).existsSync()) {
      return altPath;
    }
    
    return null;
  }

  /// Generate embedding for a single image
  Future<List<double>> generateEmbedding(String imagePath) async {
    if (useServer) {
      return _generateEmbeddingViaServer(imagePath);
    } else {
      return _generateEmbeddingViaSubprocess(imagePath);
    }
  }

  String? _cachedClipServicePath;

  /// Get cached or load clip service path
  Future<String> _getClipServicePath() async {
    if (_cachedClipServicePath == null) {
      _cachedClipServicePath = await _clipServicePath;
    }
    return _cachedClipServicePath!;
  }

  /// Generate embeddings for multiple images (batch)
  Future<Map<String, List<double>>> generateEmbeddingsBatch(
    List<String> imagePaths,
  ) async {
    if (useServer) {
      return _generateEmbeddingsBatchViaServer(imagePaths);
    } else {
      return _generateEmbeddingsBatchViaSubprocess(imagePaths);
    }
  }

  /// Generate embedding via subprocess
  Future<List<double>> _generateEmbeddingViaSubprocess(
    String imagePath,
  ) async {
    final clipServicePath = await _getClipServicePath();
    final result = await Process.run(
      _pythonExecutable,
      [clipServicePath, imagePath],
    );

    if (result.exitCode != 0) {
      throw Exception(
        'Python CLIP service failed: ${result.stderr}\n${result.stdout}',
      );
    }

    final output = result.stdout.toString().trim();
    final jsonData = jsonDecode(output) as Map<String, dynamic>;

    if (jsonData.containsKey('error')) {
      throw Exception('CLIP service error: ${jsonData['error']}');
    }

    final embedding = (jsonData['embedding'] as List)
        .map((e) => (e as num).toDouble())
        .toList();

    return embedding;
  }

  /// Generate embeddings batch via subprocess
  Future<Map<String, List<double>>> _generateEmbeddingsBatchViaSubprocess(
    List<String> imagePaths,
  ) async {
    // Write image paths to stdin
    final clipServicePath = await _getClipServicePath();
    final process = await Process.start(
      _pythonExecutable,
      [clipServicePath, '--batch'],
    );
    
    // Write image paths to stdin
    final input = imagePaths.join('\n');
    process.stdin.write(utf8.encode(input));
    await process.stdin.close();

    final exitCode = await process.exitCode;
    final output = await process.stdout.transform(utf8.decoder).join();
    final error = await process.stderr.transform(utf8.decoder).join();

    if (exitCode != 0) {
      throw Exception('Python CLIP service failed: $error\n$output');
    }

    final jsonData = jsonDecode(output) as Map<String, dynamic>;

    if (jsonData.containsKey('error')) {
      throw Exception('CLIP service error: ${jsonData['error']}');
    }

    final embeddings = <String, List<double>>{};
    final embeddingsData = jsonData['embeddings'] as Map<String, dynamic>;
    
    for (final entry in embeddingsData.entries) {
      embeddings[entry.key] = (entry.value as List)
          .map((e) => (e as num).toDouble())
          .toList();
    }

    // Report errors if any
    if (jsonData.containsKey('errors')) {
      final errors = jsonData['errors'] as Map<String, dynamic>;
      if (errors.isNotEmpty) {
        print('Warning: Some images failed to process:');
        for (final entry in errors.entries) {
          print('  ${entry.key}: ${entry.value}');
        }
      }
    }

    return embeddings;
  }

  /// Generate embedding via HTTP server
  Future<List<double>> _generateEmbeddingViaServer(String imagePath) async {
    final client = HttpClient();
    try {
      final request = await client.post('localhost', serverPort, '/embedding');
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode({'image_path': imagePath}));
      final response = await request.close();

      final responseBody = await response.transform(utf8.decoder).join();
      final jsonData = jsonDecode(responseBody) as Map<String, dynamic>;

      if (jsonData.containsKey('error')) {
        throw Exception('CLIP service error: ${jsonData['error']}');
      }

      final embedding = (jsonData['embedding'] as List)
          .map((e) => (e as num).toDouble())
          .toList();

      return embedding;
    } finally {
      client.close();
    }
  }

  /// Generate embeddings batch via HTTP server
  Future<Map<String, List<double>>> _generateEmbeddingsBatchViaServer(
    List<String> imagePaths,
  ) async {
    final client = HttpClient();
    try {
      final request = await client.post('localhost', serverPort, '/embeddings');
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode({'image_paths': imagePaths}));
      final response = await request.close();

      final responseBody = await response.transform(utf8.decoder).join();
      final jsonData = jsonDecode(responseBody) as Map<String, dynamic>;

      if (jsonData.containsKey('error')) {
        throw Exception('CLIP service error: ${jsonData['error']}');
      }

      final embeddings = <String, List<double>>{};
      final embeddingsData = jsonData['embeddings'] as Map<String, dynamic>;
      
      for (final entry in embeddingsData.entries) {
        embeddings[entry.key] = (entry.value as List)
            .map((e) => (e as num).toDouble())
            .toList();
      }

      return embeddings;
    } finally {
      client.close();
    }
  }
}

