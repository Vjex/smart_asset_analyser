import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path;
import 'package:package_config/package_config.dart';

/// Processor for Lottie assets - extracts frames from Lottie animations
class LottieProcessor {
  final String? pythonPath;
  final String projectRoot;
  final int outputSize;

  LottieProcessor({
    this.pythonPath,
    required this.projectRoot,
    this.outputSize = 512,
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
    
    throw Exception('Python not found');
  }

  String? _cachedProcessorScriptPath;

  /// Get path to asset_processor.py
  Future<String> get _processorScriptPath async {
    if (_cachedProcessorScriptPath != null) {
      return _cachedProcessorScriptPath!;
    }

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
        final scriptPath = path.join(packageRoot, 'python', 'asset_processor.py');
        if (File(scriptPath).existsSync()) {
          _cachedProcessorScriptPath = scriptPath;
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
        'asset_processor.py',
      );
      final normalized = path.normalize(scriptPath);
      if (File(normalized).existsSync()) {
        _cachedProcessorScriptPath = normalized;
        return normalized;
      }
    } catch (_) {
      // Fall through
    }
    
    // Try relative to project root (fallback)
    final altPath = path.join(projectRoot, 'python', 'asset_processor.py');
    if (File(altPath).existsSync()) {
      _cachedProcessorScriptPath = altPath;
      return altPath;
    }
    
    throw Exception(
      'asset_processor.py not found. Please ensure python/asset_processor.py exists in the package.'
    );
  }

  /// Extract key frames from Lottie animation
  /// Returns list of paths to extracted frame images
  Future<List<String>> extractFrames(
    String lottiePath, {
    List<int>? frameIndices,
  }) async {
    try {
      final processorScriptPath = await _processorScriptPath;
      final args = [
        processorScriptPath,
        'lottie',
        lottiePath,
        '--size',
        outputSize.toString(),
      ];

      if (frameIndices != null && frameIndices.isNotEmpty) {
        args.add('--frames');
        args.add(frameIndices.join(','));
      }

      final process = await Process.start(
        _pythonExecutable,
        args,
      );

      final exitCode = await process.exitCode;
      final output = await process.stdout.transform(utf8.decoder).join();
      final error = await process.stderr.transform(utf8.decoder).join();

      if (exitCode != 0) {
        throw Exception('Lottie frame extraction failed: $error\n$output');
      }

      final jsonData = jsonDecode(output) as Map<String, dynamic>;
      
      if (jsonData['success'] == true) {
        final framePaths = (jsonData['frame_paths'] as List)
            .map((p) => p as String)
            .toList();
        return framePaths;
      } else {
        throw Exception('Lottie frame extraction failed: ${jsonData['error']}');
      }
    } catch (e) {
      throw Exception('Failed to extract Lottie frames from $lottiePath: $e');
    }
  }

  /// Check if Python dependencies are available
  Future<bool> checkDependencies() async {
    try {
      final result = await Process.run(
        _pythonExecutable,
        ['-c', 'import lottie; print("OK")'],
      );
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }
}

